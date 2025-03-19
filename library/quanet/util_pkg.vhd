-- util_pkg.vhd
-- synthesizable utility functions for vhdl designs
--
-- everything defined here should begin with "u_"

-- 11/07/13 added u_rol
-- 07/20/17 added u_xor_reduce
-- 12/14/17 converted to numeric_std
-- 08/01/19 renamed "_reduce" functions to be less redundant

library ieee;
use ieee.std_logic_1164.all;

package util_pkg is

  function u_b2b(b: boolean) return std_logic;
  function u_b2i(b: boolean) return integer;

  function u_rpt(b: std_logic; i: integer) return std_logic_vector;
  function u_rpt(b: std_logic_vector; i: integer) return std_logic_vector;

  function u_or(v: std_logic_vector) return std_logic;
  function u_and(v: std_logic_vector) return std_logic;
  function u_xor(v: std_logic_vector) return std_logic;
  
  function u_encode(v: std_logic_vector ; bits: integer)   return std_logic_vector;
  function u_decode(v: std_logic_vector ; bits: integer)   return std_logic_vector;
  function u_decode(v: integer; bits: integer)   return std_logic_vector;  
  function u_flip(v: std_logic_vector)   return std_logic_vector;
  function u_byteflip(v: std_logic_vector)   return std_logic_vector;

  function u_bitcnt(v: std_logic_vector; bits: integer)   return std_logic_vector;
  -- desc:
  --   counts the number of ones in a vector
  -- inputs:
  --   v : data in
  --   bits : number of bits in the std_logic_vector that the function returns.
  function u_bitcnt(v: integer)  return integer;

  
  function u_bitwid(v: integer)   return integer;
  -- returns number of bits required to rep that int as unsigned
  -- u_bitwid(0)=0, u_bitwid(1)=1, u_bitwid(2)=2, u_bitwid(3)=2, etc

  -- overloaded for various types  
  function u_if(b: in boolean; thenval: in std_logic_vector; elseval: in std_logic_vector) return std_logic_vector;
  function u_if(b: in boolean; thenval: in std_logic; elseval: in std_logic) return std_logic;
  function u_if(b: in boolean; thenval: in integer; elseval: in integer) return integer;
  function u_if(b: in boolean; thenval: in string; elseval: in string) return string;
  function u_if(b: in boolean; thenval: in real; elseval: in real) return real;
  
  -- unsigned min
  function u_min(l, r: integer)
    return integer;
  -- desc: same as in std_logic_arith, which unfortunately doesn't export min(). 

  -- unsigned max
  function u_max(l, r: integer)
    return integer;
  -- desc: same as in std_logic_arith, which unfortunately doesn't export max().
  function u_max_unsigned(l, r: std_logic_vector) -- unsigned
    return std_logic_vector;

  function u_log2(a: integer)
    return integer;
  -- desc: returns number of bits reqd to hold integer a:
  -- 0->0, 1->1, 2->2, 3->2, 4->3, 5->3

  function u_rol(a: std_logic_vector; by: integer)
    return std_logic_vector;

  function u_extl(a: std_logic_vector; l: integer)
    return std_logic_vector;
  -- desc: unsigned extension (pad zeros on left)

  function u_extls(a: std_logic_vector; l: integer)
    return std_logic_vector;
  
  function u_extr(a: std_logic_vector; l: integer)
    return std_logic_vector;
  -- extend a to length l by padding zeros on the right

  function u_g2b(g: std_logic_vector)
    return std_logic_vector;
  -- graycode to binary

  function u_b2g(b: std_logic_vector)
    return std_logic_vector;
  -- binary to graycode
  
  function u_add_s(a: std_logic_vector; b: std_logic_vector)
    return std_logic_vector;
  -- add signed arith
  
  function u_inc(v: std_logic_vector)
    return std_logic_vector;
  -- increment unsigned
  
  function u_dec(v: std_logic_vector)
   return std_logic_vector;
  -- decrement unsigned
  
  function u_neg(v: std_logic_vector)
    return std_logic_vector;
  -- consider v to be signed, and negate it.
  
  function u_abs(v: std_logic_vector)
    return std_logic_vector;
  -- consider v to be signed, take absolute value
  
  function u_shift_left(v: std_logic_vector; count: std_logic_vector)
    return std_logic_vector;
  
  function u_shift_right_u(v: std_logic_vector; count: std_logic_vector)
    return std_logic_vector;
  -- shift right unsigned
  
  function u_shift_right_a(v: std_logic_vector; count: std_logic_vector)
    return std_logic_vector;
  -- shift right arithmatic  

  
end util_pkg;


library ieee;
use ieee.numeric_std.all;
--use ieee.std_logic_misc.all;
-- don't use ieee.std_logic_arith.all or ieee.std_logic_unsigned.all anymore
package body util_pkg is

  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.
  function u_b2b(b: boolean)
    return std_logic is
  begin
    if (b) then return '1';
    else return '0';
    end if;
  end function u_b2b;
 
  -- b2i stands for "Boolean to Integer"
  function u_b2i(b: boolean)
    return integer is
  begin
    if (b) then return 1;
    else return 0;
    end if;
  end function u_b2i;

  

  function u_or(v: std_logic_vector)
    return std_logic is
  begin
    return u_b2b(unsigned(v)/=0);
  end function u_or;
  
  function u_and(v: std_logic_vector)
    return std_logic is
  begin
    return u_b2b(unsigned(not v)=0);
  end function u_and;
    

  function u_xor(v: std_logic_vector)
    return std_logic is
    variable r: std_logic := '0';
  begin
    for i in v'range loop
      r := r xor v(i);
    end loop;
    return r;
  end function u_xor;


  
  function u_rpt(b: std_logic; i: integer)
    return std_logic_vector is
    variable v: std_logic_vector(i-1 downto 0);
  begin
    for j in v'range loop
      v(j) := b;
    end loop;
    return v;
  end function u_rpt;

  
  function u_rpt(b: std_logic_vector; i: integer)
    return std_logic_vector is
    constant BW: integer := b'length;
    variable v: std_logic_vector(BW*i-1 downto 0);
  begin
    for j in 0 to i-1 loop
      v(BW*j+BW-1 downto BW*j) := b;
    end loop;
    return v;
  end function u_rpt;

  

  -- encode: more significant bits get priority
  function u_encode(v: std_logic_vector; bits: integer)
    return std_logic_vector is
    variable vv: std_logic_vector(v'length-1 downto 0) := v;
  begin
    for i in vv'range loop
      if (vv(i)='1') then
        return std_logic_vector(to_unsigned(i, bits));
      end if;
    end loop;  -- i
    return std_logic_vector(to_unsigned(0, bits));
  end function u_encode;
  
  function u_decode(v: std_logic_vector; bits: integer)
  -- sets vv(v)='1', others zero
    return std_logic_vector is
    variable vv: std_logic_vector(bits-1 downto 0);
  begin
    -- You would think that the following would work, but xilinx synthesis
    -- of it sometimes yields a "simulation mismatch" warning.
    --    vv := (others => '0');
    --    j := conv_integer(v);
    --    if (j<bits) then
    --      vv(j) := '1';
    --    end if;
    for i in vv'range loop
      vv(i) := u_and(not (v xor std_logic_vector(to_unsigned(i, v'length))));
    end loop;
    return vv;
  end function u_decode;

  function u_decode(v: integer; bits: integer)
    return std_logic_vector is
    variable vv: std_logic_vector(bits-1 downto 0);
  begin
    for i in vv'range loop
      vv(i) := u_b2b(v=i);
    end loop;
    return vv;
  end function u_decode;


  function u_bitcnt(v: std_logic_vector; bits: integer)
    return std_logic_vector is
    variable sum: unsigned(bits-1 downto 0);
  begin
    sum := (others => '0');
    for j in v'range loop
      if (v(j)='1') then sum:=sum+1; end if;
    end loop;
    return std_logic_vector(sum);
  end function u_bitcnt;

  function u_bitcnt(v: integer)
    return integer is
    variable vv: integer := v;
    variable sum: integer := 0;
  begin
    for j in 0 to 31 loop
      if ((vv mod 2)=1) then
        sum := sum+1;
      end if;
      vv := vv / 2;
    end loop;
    return sum;
  end function u_bitcnt;

  function u_bitwid(v: integer)
    return integer is
    variable vv, bw: integer := 0;
  begin
    vv:=v;
    while (vv>0) loop
      vv  := vv / 2;
      bw := bw+1;
    end loop;
    return bw;
  end function u_bitwid;
  
  function u_if(b: in boolean;
              thenval: in std_logic_vector;
              elseval: in std_logic_vector)
    return std_logic_vector is
  begin
    if (b) then
      return thenval;
    else
      return elseval;
    end if;
  end function u_if;


  function u_if(b: in boolean;
              thenval: in std_logic;
              elseval: in std_logic)
    return std_logic is
  begin
    if (b) then
      return thenval;
    else
      return elseval;
    end if;
  end function u_if;

  
  function u_if(b: in boolean;
              thenval: in integer;
              elseval: in integer)
    return integer is
  begin
    if (b) then
      return thenval;
    else
      return elseval;
    end if;
  end function u_if;

  function u_if(b: in boolean;
              thenval: in real;
              elseval: in real)
    return real is
  begin
    if (b) then
      return thenval;
    else
      return elseval;
    end if;
  end function u_if;
  

  function u_if(b: in boolean;
              thenval: in string;
              elseval: in string)
    return string is
  begin
    if (b) then
      return thenval;
    else
      return elseval;
    end if;
  end function u_if;

  
  function u_flip(v: std_logic_vector)
    return std_logic_vector is
    variable vi, vo: std_logic_vector(v'length-1 downto 0);
    variable j: integer;
  begin
    vi := v;
    for j in vi'range loop
      vo(v'length-1-j) := vi(j);
    end loop;
    return vo;
  end function u_flip;


  function u_byteflip(v: std_logic_vector)
    return std_logic_vector is
    variable vi, vo: std_logic_vector(v'length-1 downto 0);
--    variable j,: integer;
    constant nb: integer := v'length/8;
  begin
    vi := v;
    for b in 0 to nb-1 loop
      for i in 0 to 7 loop
        vo((nb-1-b)*8+i) := vi(b*8+i);
      end loop;
    end loop;
    return vo;
  end function u_byteflip;
  
  function u_min(l, r: integer) return integer is
  begin
    if (r < l) then
      return r;
    else
      return l;
    end if;
  end;

  function u_max(l, r: integer) return integer is
  begin
    if (r > l) then
      return r;
    else
      return l;
    end if;
  end;
  
  function u_max_unsigned(l, r: std_logic_vector) return std_logic_vector is
  begin
    if (r > l) then
      return r;
    else
      return l;
    end if;
  end;

  function u_log2(a: integer) return integer is
  -- returns number of bits reqd to hold integer a:
  -- 0->0, 1->1, 2->2, 3->2, 4->3, 5->3
    variable p,e: integer;
  begin
    p:=1;
    e:=0;
    while (p<=a) loop
      e:=e+1;
      p:=p*2;
    end loop;
    return e;
  end;

  function u_rol(a: std_logic_vector; by: integer)
    return std_logic_vector is
    variable v: std_logic_vector(a'length-1 downto 0):=a;
  begin
    return v(a'length-1-by downto 0)&v(a'length-1 downto a'length-by);
  end;

  function u_extl(a: std_logic_vector; l: integer)
    return std_logic_vector is
    variable v: std_logic_vector(l-1 downto 0):=(others=>'0');
  begin
    v(a'length-1 downto 0) := a;
    return v;
  end;

  function u_extls(a: std_logic_vector; l: integer)
    return std_logic_vector is
    variable v: std_logic_vector(l-1 downto 0):=(others=>a(a'left));
  begin
    v(a'length-1 downto 0) := a;
    return v;
  end;
  
  function u_extr(a: std_logic_vector; l: integer)
    return std_logic_vector is
    variable v: std_logic_vector(l-1 downto 0):=(others=>'0');
  begin
    v(l-1 downto l-a'length) := a;
    return v;
  end;

  function u_g2b(g: std_logic_vector)
  return std_logic_vector is
--    constant W: integer := g'length;
    variable r: std_logic_vector(g'length-1 downto 0);
  begin
    r(g'length-1) := g(g'length-1);
    for i in g'length-1 downto 1 loop
      r(i-1) := r(i) xor g(i-1);
    end loop;
    return r;
  end function u_g2b;

  function u_b2g(b: std_logic_vector)
  return std_logic_vector is
    variable g: std_logic_vector(b'length-1 downto 0);
  begin
    g(b'length-1) := b(b'length-1);
    for i in b'length-1 downto 1 loop
      g(i-1) := b(i) xor b(i-1);
    end loop;
    return g;
   end function u_b2g;

  function u_add_s(a: std_logic_vector; b: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(signed(a)+signed(b));
  end function u_add_s;

    
  function u_inc(v: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(unsigned(v)+1);
  end function u_inc;
  
  function u_dec(v: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(unsigned(v)-1);
  end function u_dec;

  function u_neg(v: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(-signed(v));
  end function u_neg;

  function u_abs(v: std_logic_vector)
   return std_logic_vector is
  begin
    if (v(v'left)='1') then
      return u_neg(v);
    else
      return v;
    end if;
  end function u_abs;

  function u_shift_left(v: std_logic_vector; count: std_logic_vector)
    return std_logic_vector is
  begin
    return std_logic_vector(shift_left(unsigned(v),
                                       to_integer(unsigned(count))));
    return v;
  end function u_shift_left;
  
  function u_shift_right_u(v: std_logic_vector; count: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(shift_right(unsigned(v),
                                        to_integer(unsigned(count))));
  end function u_shift_right_u;

  function u_shift_right_a(v: std_logic_vector; count: std_logic_vector)
   return std_logic_vector is
  begin
    return std_logic_vector(shift_right(signed(v),
                                        to_integer(unsigned(count))));
    return v;
  end function u_shift_right_a;
    
  
end util_pkg;
