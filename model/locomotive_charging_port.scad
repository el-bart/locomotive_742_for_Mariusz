include <m3d/all.scad>

magnet_d = 6;
magnet_h = 3;
magnet_surround = 2;


module charging_port()
{
  
}


module charging_plug()
{
  w = magnet_surround;
  s = [magnet_d+2*w, 20, magnet_h+w];
  cw = 1.8; // cable width
  difference()
  {
    side_rounded_cube(s, 1, $fn=fn(20));
    translate([s.x/2, s.y-magnet_d/2-w, 0])
    {
      // magnet slot
      translate([0, 0, w+eps])
        cylinder(d=magnet_d, h=magnet_h+eps, $fn=fn(50));
      // bottom cable connection
      translate([0, 0, -eps])
        cylinder(d=cw, h=s.z+2*eps, $fn=fn(50));
      // back cable connection
      translate([-cw/2, -s.y, -eps])
        cube([cw, s.y, cw+eps]);
    }
  }
}


//charging_port();

for(dx = [0:1])
  translate([-(dx+1)*(magnet_d + 2*magnet_surround + 4), 0, 0])
    charging_plug();
