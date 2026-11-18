    vec4 marks = markvec(p);
    if (marks.a > 0.0)
        color = marks + color * (1.0 - marks.a);
