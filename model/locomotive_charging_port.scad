include <m3d/all.scad>

magnet_d = 6;
magnet_h = 3;
magnet_surround = 2;
spacing = 0.1;
cable_width = 1.8;


module magnet_mock()
{
  cylinder(d=magnet_d, h=magnet_h, $fn=fn(20));
}


module charging_port()
{
  w = magnet_surround;
  d = magnet_d;
  side = d+2*w;
  cw = cable_width;

  module bottom()
  {
    difference()
    {
      s = side*[1,1,0] + [0,0,magnet_h];
      cube(s);
      translate([s.x/2, s.y/2, -eps])
        cylinder(d=magnet_d+2*spacing, h=magnet_h+2*eps, $fn=fn(50));
    }
  }

  module top()
  {
    translate([0, side, magnet_h])
      rotate([90, 0, 0])
        linear_extrude(side)
          polygon([
            [0, 0],
            [0, d],
            [side, 0]
          ]);
  }

  difference()
  {
    union()
    {
      bottom();
      top();
    }
    // cable hole
    translate([-side/2, side/2-cw/2, magnet_h-eps])
      cube([side, cw, cw+eps]);
  }
}


module charging_plug()
{
  w = magnet_surround;
  s = [magnet_d+2*w, 20, magnet_h+w];
  cw = cable_width;
  rounding = 2;

  difference()
  {
    side_rounded_cube(s, rounding, $fn=fn(20));
    translate([s.x/2, s.y-magnet_d/2-w, 0])
    {
      // magnet slot
      translate([0, 0, w+eps])
      {
        cylinder(d=magnet_d+2*spacing, h=magnet_h+eps, $fn=fn(50));
        %if($preview)
          magnet_mock();
      }
      // bottom cable connection
      translate([0, 0, -eps])
        cylinder(d=cw, h=s.z+2*eps, $fn=fn(50));
      // back cable connection
      translate([-cw/2, -s.y, -eps])
        cube([cw, s.y, cw+eps]);
    }
  }
}


rotate([0, -90, 0])
  charging_port();

translate([3, 0, 0])
  charging_plug();
