{
  abs,
  atan2,
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
  inherit (self) DOT DOTW GRID LAV LIME MUSTARD PAD PAGE PAPER PINK SPEED hash pad;
  prelude = import ./ozette-prelude.data.nix glsl self;
in {
  consts =
    prelude.consts
    // {
      DOTW = 0.16;
      SPEED = 0.03;
    };
  fns =
    prelude.fns
    // {
      mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
        fragColor,
        fragCoord,
        uv,
        a,
        t,
        col,
        g,
      }: [
        (local uv vec2 [fragCoord "/" iResolution.y])
        (local a float [iResolution.x "/" iResolution.y])
        (local t float [iTime "*" SPEED])
        (local col vec3 (mix PAPER PAGE [1.0 "-" uv.y]))
        (local g vec2 [(mod fragCoord GRID) "-" 0.5 "*" GRID])
        (set col (mix col DOT [DOTW "*" [1.0 "-" (smoothstep 1.2 2.0 (length g))]]))
        (set col (pad col uv (vec2 [a "*" 0.12 "+" 0.03 "*" (sin [t "*" 1.3])] [0.78 "+" 0.03 "*" (cos [t "*" 1.1])]) 0.26 [0.6 "+" 0.2 "*" (sin t)] LAV))
        (set col (pad col uv (vec2 [a "*" 0.36 "+" 0.04 "*" (cos [t "*" 0.9])] [0.12 "+" 0.03 "*" (sin [t "*" 1.4])]) 0.2 [2.2 "+" 0.2 "*" (cos [t "*" 0.8])] MUSTARD))
        (set col (pad col uv (vec2 [a "*" 0.62 "+" 0.03 "*" (sin [t "*" 1.2 "+" 2.0])] [0.9 "+" 0.02 "*" (cos [t "*" 1.6])]) 0.17 [4.0 "+" 0.2 "*" (sin [t "*" 1.1])] LIME))
        (set col (pad col uv (vec2 [a "*" 0.84 "+" 0.04 "*" (cos [t "*" 1.0 "+" 1.0])] [0.3 "+" 0.03 "*" (sin [t "*" 0.7])]) 0.3 [5.1 "+" 0.2 "*" (cos [t "*" 0.9])] PINK))
        (set col (pad col uv (vec2 [a "*" 0.97 "+" 0.02 "*" (sin [t "*" 1.5])] [0.82 "+" 0.03 "*" (sin [t "*" 1.2])]) 0.12 [1.4 "+" 0.2 "*" (sin [t "*" 1.3])] LAV))
        (update col "+=" [[(hash [fragCoord "+" (fract iTime)]) "-" 0.5] "/" 255.0])
        (set fragColor (vec4 col 1.0))
      ]);
      pad = fn vec3 [{col = vec3;} {p = vec2;} {c = vec2;} {r = float;} {turn = float;} {hue = vec3;}] ({
        col,
        p,
        c,
        r,
        turn,
        hue,
        d,
        ang,
        notch,
        px,
        m,
        c2,
      }: [
        (local d vec2 [p "-" c])
        (local ang float [(atan2 d.y d.x) "-" turn])
        (local notch float (smoothstep 0.1 0.13 (abs [(mod [ang "+" 3.14159] 6.28318) "-" 3.14159])))
        (local px float [1.5 "/" iResolution.y])
        (local m float [[1.0 "-" (smoothstep [r "-" px] [r "+" px] (length d))] "*" notch])
        (local c2 vec3 (mix col hue PAD))
        (return (mix col c2 m))
      ]);
    };
  inherit (prelude) paper;
}
