include <m3d/all.scad>

wall = 0.45*3;

fan_size = [40, 40, 10];
fan_spacing = 0.5;
fan_angle = 57; // [deg] from vertical
fan_rim = 1.5;

bottom_space = 15;

assert(fan_rim > fan_spacing);


module fan_mock()
{
  cube(fan_size);
}

module box()
{
  module main()
  {
    size = [45, 40+5, 40];
    difference()
    {
      cube(size);
      translate(wall*[1,1,1])
        cube(size - wall*[2,2,2]);
    }
  }

  module fan_mount()
  {
    size = fan_size + (fan_spacing + wall)*[2,2,0] + [0,0,wall];
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

  main();

  //fan_mount();
}

box();
