{
  ozette,
  array,
  cos,
  dot,
  exp,
  float,
  fn,
  for,
  fract,
  iResolution,
  iTime,
  in',
  inc,
  index,
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
  sized,
  smoothstep,
  update,
  vec2,
  vec3,
  vec4,
  void,
  rgb,
  ...
} @ glsl: self: let
  inherit (self) BASE_BOTTOM BASE_TOP DOT DOTW GRID HUE LAV LIME MUSTARD PINK PLUM PLUMW RING RIPPLE SPEED blob fbm hash;
  prelude = import ./ozette-prelude.data.nix glsl self;
in {
  consts =
    prelude.consts
    // {
      LIME = rgb ozette.lime;
      MUSTARD = rgb ozette.mustard;
      RIPPLE = 0.25;
      SPEED = 0.02;
    };
  fns =
    prelude.fns
    // {
      blob = fn float [{uv = vec2;} {c = vec2;} {r = float;}] ({
        uv,
        c,
        r,
        d,
      }: [
        (local d vec2 [uv "-" c])
        (return (exp [(neg (dot d d)) "/" [r "*" r]]))
      ]);
      mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
        fragColor,
        fragCoord,
        uv,
        t,
        w,
        a,
        col,
        r,
        cs,
        g,
        pip,
      }: [
        (local uv vec2 [fragCoord "/" iResolution.y])
        (local t float [iTime "*" SPEED])
        (local w vec2 [uv "+" 0.18 "*" (vec2 (fbm [uv "*" 1.3 "+" (vec2 t 0.0)]) (fbm [uv "*" 1.3 "+" (vec2 3.1 (neg t))])) "-" 0.09])
        (local a float [iResolution.x "/" iResolution.y])
        (local col vec3 (mix BASE_TOP BASE_BOTTOM (smoothstep 0.0 1.0 [1.0 "-" uv.y])))
        (set col (mix col LAV [HUE "*" 1.0 "*" (blob w (vec2 [a "*" [0.22 "+" 0.04 "*" (sin [t "*" 0.7])]] 0.72) 0.55)]))
        (set col (mix col PINK [HUE "*" 0.75 "*" (blob w (vec2 [a "*" [0.78 "+" 0.03 "*" (cos [t "*" 0.6])]] 0.78) 0.48)]))
        (set col (mix col MUSTARD [HUE "*" 0.55 "*" (blob w (vec2 [a "*" [0.58 "+" 0.04 "*" (sin [t "*" 0.5 "+" 2.0])]] 0.08) 0.42)]))
        (set col (mix col LIME [HUE "*" 0.6 "*" (blob w (vec2 [a "*" [0.92 "+" 0.02 "*" (sin [t "*" 0.8])]] 0.2) 0.4)]))
        (set col (mix col PLUM [PLUMW "*" (blob w (vec2 [a "*" 0.45] [0.45 "+" 0.05 "*" (sin [t "*" 0.4])]) 0.6)]))
        (local r float 0.0)
        (local cs (sized vec2 3) (array vec2 [(vec2 [0.3 "*" a] 0.35) (vec2 [0.7 "*" a] 0.62) (vec2 [0.52 "*" a] 0.18)]))
        (for ({
          i,
          d,
        }: {
          init = local i int 0;
          test = [i "<" 3];
          step = inc i;
          body = [
            (local d float (length [w "-" (index cs i)]))
            (update r "+=" [(sin [d "*" 38.0 "-" iTime "*" RIPPLE "+" (float i) "*" 2.1]) "*" (exp [(neg d) "*" 2.2])])
          ];
        }))
        (update col "+=" [RING "*" r])
        (local g vec2 [(mod fragCoord GRID) "-" 0.5 "*" GRID])
        (local pip float [1.0 "-" (smoothstep 1.1 1.9 (length g))])
        (set col (mix col DOT [DOTW "*" pip "*" [0.6 "+" 0.4 "*" (fbm [uv "*" 2.0 "-" t])]]))
        (update col "+=" [[(hash [fragCoord "+" (fract iTime)]) "-" 0.5] "/" 255.0])
        (set fragColor (vec4 col 1.0))
      ]);
    };
}
