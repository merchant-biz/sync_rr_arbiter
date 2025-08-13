--------------------------------------------------------------------------------
-- Synchronous round-robin arbiter for 'n' requesters, 
-- output one-hot grant, and with fair arbitration
--
-- @version 0.1.0
--
-- @author Jordan Downie <jpjdownie.biz@gmail.com>
-- @section LICENSE
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
-- NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity arbiter is
    generic(
        requesters : integer := 7
    );
    port(
		rst : in std_logic;
        clk : in std_logic;
        req : in std_logic_vector(requesters - 1 downto 0);
        gnt : out std_logic_vector(requesters - 1 downto 0)
    );
end arbiter;

architecture rtl of arbiter is

signal s_next_ptr : integer := 0;

function any_highs(v : std_logic_vector) return boolean is
begin
    for i in v'range loop
        if v(i) = '1' then
            return true;
        end if;
    end loop;
    return false;
end function;

function rr_first_index(v : std_logic_vector; start : integer) return integer is
    constant W : integer := v'length;
    variable idx : integer;
begin
    if W = 0 then
        return -1;
    end if;

    -- walk start, start+1, ..., start+W-1 (mod W)
    for step in 0 to W-1 loop
        idx := (start + step) mod W;
        if v(idx) = '1' then
            return idx;
        end if;
    end loop;

    return -1;
end function;

begin
main : process(clk)
    variable win_idx : integer;  -- winner this cycle
begin
	if rising_edge(clk) then
		if rst = '1' then
			s_next_ptr <= 0;
			gnt <= (others => '0');
		else
			-- default no grant
			gnt <= (others => '0');

			if any_highs(req) then
				-- pick first requester starting at pointer (wrapping)
				win_idx := rr_first_index(req, s_next_ptr);

				if win_idx /= -1 then
					gnt(win_idx) <= '1';
					s_next_ptr <= (win_idx + 1) mod requesters;
				else
					-- defensive
					s_next_ptr <= s_next_ptr;
				end if;
			else
				-- no requests
				s_next_ptr <= s_next_ptr;
			end if;
		end if;
	end if;
end process;


end architecture;