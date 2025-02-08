include <m3d/all.scad>

wall = 0.45*3;

box_size = [45-1.3, 40+5, 40];

fan_size = [40, 40, 10];
fan_spacing = 0.5;
fan_angle = 57; // [deg] from vertical
fan_rim = 1.5;
fan_mount_size = fan_size + (fan_spacing + wall)*[2,2,0] + [0,0,wall];

bottom_space = 10 + wall;

assert(fan_rim > fan_spacing);


module fan_mock()
{
  cube(fan_size);
}

module box()
{
  module main()
  {
    size = box_size;
    difference()
    {
      cube(size);
      translate(wall*[1,1,1])
        cube(size - wall*[2,2,2]);
    }
  }

  module fan_mount()
  {
    size = fan_mount_size;
    module assembly()
    {
      difference()
      {
        cube(size);
        translate(wall*[1,1,0])
        {
          // above-the-rim cut
          translate([0,0,wall])
            cube(fan_size + fan_spacing*[2,2,0] + [0,0,size.z]);
          // in-rim cut
          translate((fan_spacing+fan_rim)*[1,1,0] - [0,0,eps])
          {
            cube(fan_size - fan_rim*[2,2,0] + [0,0,eps]);
          }
          %if($preview)
            translate(fan_spacing*[1,1,0] + [0,0,wall])
              fan_mock();
        }
      }
    }
    translate([0, -size.y, 0])
    assembly();
  }

  module ventilation_holes()
  {
    off = 2;
    cut_size = [30, 3*wall, off];
    for(z=[1:8])
      translate([wall + off, -wall, 8 + z*(off + wall)])
        cube(cut_size);
  }

  module cable_holes()
  {
    translate(wall*[0,-1,1])
    {
      // GND and +5V lines
      dx = wall+2;
      s = [10+2, 5, 5+2];
      for(x=[dx, box_size.x-dx-s.x])
        translate([x, 0, 0])
          cube(s);
      // USB-C socket
      translate([box_size.x-dx-12, box_size.y-wall, 0])
     cube([12, 3*wall, 8]);
    }
  }

  difference()
  {
    main();
    // diagonal cut
    translate([-eps, box_size.y, bottom_space])
      rotate([fan_angle, 0, 0])
        cube(2*[box_size.x, box_size.y, 0] + [0, 0, fan_mount_size.y]);
    ventilation_holes();
    cable_holes();
  }
  // fan_mount assembly
  assert( box_size.x - fan_mount_size.x == 0 );
  translate([-eps, box_size.y, bottom_space])
    rotate([fan_angle-90, 0, 0])
      fan_mount();
}

box();
