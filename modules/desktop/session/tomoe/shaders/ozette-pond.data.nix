{
  abs,
  clamp,
  exp,
  float,
  fn,
  for,
  fract,
  iResolution,
  iTime,
  in',
  inc,
  int,
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
  inherit (self) BODY DOT DOTW GLINT GRID LAV LIME LINES MUSTARD PAGE PAPER PINK SCALE SPEED caustic fbm hash;
  prelude = import ./ozette-prelude.data.nix glsl self;
in {
  consts =
    prelude.consts
    // {
      DOTW = 0.08;
      SCALE = 4.5;
      SPEED = 0.03;
    };
  fns =
    prelude.fns
    // {
      caustic = fn float [{p = vec2;} {t = float;}] ({
        p,
        t,
        q,
        f,
      }: [
        (local q vec2 p)
        (for ({i}: {
          init = local i int 0;
          test = [i "<" 3];
          step = inc i;
          body = [
            (update q "+=" [0.6 "*" (vec2 (sin [q.y "*" 1.7 "+" t "+" (float i)]) (sin [q.x "*" 1.5 "-" t "*" 0.8 "-" (float i)]))])
          ];
        }))
        (local f float [(sin [q.x "*" 2.0]) "+" (sin [q.y "*" 2.0])])
        (return (exp [(neg (abs f)) "*" 5.0]))
      ]);
      mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
        fragColor,
        fragCoord,
        uv,
        a,
        t,
        col,
        h,
        tint,
        c,
        g,
      }: [
        (local uv vec2 [fragCoord "/" iResolution.y])
        (local a float [iResolution.x "/" iResolution.y])
        (local t float [iTime "*" SPEED])
        (local col vec3 (mix PAPER PAGE [1.0 "-" uv.y]))
        (local h float (fbm [uv "*" 0.8 "+" (vec2 [t "*" 0.05] [(neg t) "*" 0.03])]))
        (local tint vec3 (mix LAV PINK (smoothstep 0.35 0.65 [h "+" 0.25 "*" (sin [uv.x "/" a "*" 3.0 "+" t "*" 0.1])])))
        (set tint (mix tint LIME (smoothstep 0.55 0.75 (fbm [uv "*" 0.6 "-" (vec2 [t "*" 0.04] 2.0)]))))
        (set tint (mix tint MUSTARD [0.6 "*" (smoothstep 0.6 0.8 (fbm [uv "*" 0.7 "+" (vec2 4.0 [t "*" 0.03])]))]))
        (set col (mix col tint BODY))
        (local c float (caustic [uv "*" SCALE "+" (vec2 0.0 7.0)] t))
        (set col (mix col GLINT [(clamp c 0.0 1.0) "*" LINES]))
        (local g vec2 [(mod fragCoord GRID) "-" 0.5 "*" GRID])
        (set col (mix col DOT [DOTW "*" [1.0 "-" (smoothstep 1.1 1.9 (length g))]]))
        (update col "+=" [[(hash [fragCoord "+" (fract iTime)]) "-" 0.5] "/" 255.0])
        (set fragColor (vec4 col 1.0))
      ]);
    };
  inherit (prelude) paper;
}
