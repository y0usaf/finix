    vec4 ink = D4(INK);
    float marks = marked(p) * ink.a;
    if (marks > 0.0)
        color = vec4(ink.rgb * marks + color.rgb * (1.0 - marks),
                     marks + color.a * (1.0 - marks));
