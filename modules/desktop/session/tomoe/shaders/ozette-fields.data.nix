{
  cos,
  float,
  fn,
  fract,
  iResolution,
  iTime,
  in',
  length,
  local,
  mix,
  mod,
  neg,
  out,
  return,
  set,
  sin,
  smoothstep,
  update,
  vec2,
  vec3,
  vec4,
  void,
  ...
} @ glsl: self: let
  inherit (self) DOT DOTW GRID LAV LIME MUSTARD PAGE PAPER PINK SPEED STRENGTH fbm field hash;
  prelude = import ./ozette-prelude.data.nix glsl self;
in {
  consts =
    prelude.consts
    // {
      DOTW = 0.1;
      SPEED = 0.02;
    };
  fns =
    prelude.fns
    // {
      field = fn float [{p = vec2;} {c = vec2;} {r = float;}] ({
        p,
        c,
        r,
      }: [
        (return [1.0 "-" (smoothstep [r "*" 0.82] [r "*" 1.12] (length [p "-" c]))])
      ]);
      mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
        fragColor,
        fragCoord,
        uv,
        a,
        t,
        w,
        col,
        g,
      }: [
        (local uv vec2 [fragCoord "/" iResolution.y])
        (local a float [iResolution.x "/" iResolution.y])
        (local t float [iTime "*" SPEED])
        (local w vec2 [uv "+" 0.22 "*" (vec2 (fbm [uv "*" 0.9 "+" (vec2 t 1.7)]) (fbm [uv "*" 0.9 "+" (vec2 5.2 (neg t))])) "-" 0.11])
        (local col vec3 (mix PAPER PAGE [1.0 "-" uv.y]))
        (set col (mix col LAV [STRENGTH "*" (field w (vec2 [a "*" [0.2 "+" 0.05 "*" (sin [t "*" 2.1])]] 0.66) 0.62)]))
        (set col (mix col MUSTARD [STRENGTH "*" (field w (vec2 [a "*" [0.5 "+" 0.04 "*" (cos [t "*" 1.7])]] 0.02) 0.5)]))
        (set col (mix col PINK [STRENGTH "*" (field w (vec2 [a "*" [0.74 "+" 0.04 "*" (sin [t "*" 1.9 "+" 1.0])]] 0.86) 0.55)]))
        (set col (mix col LIME [STRENGTH "*" (field w (vec2 [a "*" [0.96 "+" 0.03 "*" (cos [t "*" 2.3])]] 0.24) 0.48)]))
        (set col (mix col LAV [STRENGTH "*" 0.7 "*" (field w (vec2 [a "*" [0.38 "+" 0.03 "*" (sin [t "*" 1.3])]] 1.08) 0.36)]))
        (local g vec2 [(mod fragCoord GRID) "-" 0.5 "*" GRID])
        (set col (mix col DOT [DOTW "*" [1.0 "-" (smoothstep 1.1 1.9 (length g))]]))
        (update col "+=" [[(hash [fragCoord "+" (fract iTime)]) "-" 0.5] "/" 255.0])
        (set fragColor (vec4 col 1.0))
      ]);
    };
  inherit (prelude) paper;
}
