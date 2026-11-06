{
  ozette,
  dot,
  float,
  floor,
  fn,
  for,
  fract,
  inc,
  int,
  local,
  mat2,
  mix,
  return,
  set,
  update,
  vec2,
  rgb,
  ...
}: self: let
  inherit (self) hash noise;
in {
  consts = {
    GRID = 44.0;
    LAV = rgb ozette.lavender;
    PINK = rgb ozette.pink;
  };
  fns = {
    fbm = fn float [{p = vec2;}] ({
      p,
      s,
      a,
    }: [
      (local s float 0.0)
      (local a float 0.5)
      (for ({i}: {
        init = local i int 0;
        test = [i "<" 3];
        step = inc i;
        body = [
          (update s "+=" [a "*" (noise p)])
          (set p [(mat2 1.6 1.2 (-1.2) 1.6) "*" p])
          (update a "*=" 0.5)
        ];
      }))
      (return s)
    ]);
    hash = fn float [{p = vec2;}] ({p}: [
      (set p (fract [p "*" (vec2 123.34 456.21)]))
      (update p "+=" (dot p [p "+" 45.32]))
      (return (fract [p.x "*" p.y]))
    ]);
    noise = fn float [{p = vec2;}] ({
      p,
      i,
      f,
      u,
    }: [
      (local i vec2 (floor p))
      (local f vec2 (fract p))
      (local u vec2 [f "*" f "*" [3.0 "-" 2.0 "*" f]])
      (return (mix (mix (hash i) (hash [i "+" (vec2 1.0 0.0)]) u.x) (mix (hash [i "+" (vec2 0.0 1.0)]) (hash [i "+" (vec2 1.0 1.0)]) u.x) u.y))
    ]);
  };
  paper = {
    dark = {
      DOT = rgb ozette.lime;
      LIME = rgb ozette.mint;
      MUSTARD = rgb ozette.periwinkle;
      PAGE = rgb ozette.night;
      PAPER = rgb ozette.ink;
    };
    light = {
      DOT = rgb ozette.moss;
      LIME = rgb ozette.lime;
      MUSTARD = rgb ozette.mustard;
      PAGE = rgb ozette.mist;
      PAPER = rgb ozette.snow;
    };
  };
}
