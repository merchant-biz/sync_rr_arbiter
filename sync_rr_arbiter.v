////////////////////////////////////////////////////////////////////////////////
// Synchronous round-robin arbiter for 'n' requesters, 
// output one-hot grant, and with fair arbitration
//
// @version 0.1.0
//
// @author Jordan Downie <jpjdownie.biz@gmail.com>
// @section LICENSE
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
// NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENT IAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////////////////////////////////////
module arbiter #(
    parameter requesters = 5
)(
    input  wire                   rst,
    input  wire                   clk,
    input  wire [requesters-1:0]  req,
    output reg  [requesters-1:0]  gnt
);

function integer clog2;
    input integer value;
    integer i;
begin
    value = value - 1;
    for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
    clog2 = (i == 0) ? 1 : i;
end
endfunction

function integer rr_first_index;
    input [requesters-1:0] v;
    input integer start;
    integer step;
    integer idx;
    reg found;
begin
    rr_first_index = -1; // default
    found = 1'b0;
    for (step = 0; step < requesters; step = step + 1) begin
        idx = start + step;
        if (idx >= requesters) idx = idx - requesters; 
        if (v[idx] && !found) begin
            rr_first_index = idx;
            found = 1'b1;  // emulate break
        end
    end
end
endfunction

function any_highs;
    input [requesters-1:0] v;
begin
    any_highs = |v;
end
endfunction

localparam PTRW = clog2(requesters);
reg [PTRW-1:0] s_next_ptr;

integer win_idx;

always @(posedge clk) begin
    if (rst) begin
        s_next_ptr <= {PTRW{1'b0}};
        gnt        <= {requesters{1'b0}};
    end else begin
        gnt <= {requesters{1'b0}};  // default each cycle

        if (any_highs(req)) begin
            win_idx = rr_first_index(req, s_next_ptr);
            if (win_idx != -1) begin
                gnt[win_idx] <= 1'b1;
					 // wrap to avoid %
                if (win_idx == requesters-1) 
                    s_next_ptr <= {PTRW{1'b0}};
                else
                    s_next_ptr <= win_idx[PTRW-1:0] + {{(PTRW-1){1'b0}},1'b1};
            end
        end
    end
end

endmodule
