# Taken from https://gist.github.com/camtheman256/028aa2f1ced68cd435093a2d4680cf88

# Is jj installed?
# Probably unnecessary with the current nix config, but hey, overkill is the way
if not command -sq jj
    return 1
end

# Are we in a jj repo?
if not jj root --quiet &>/dev/null
    return 1
end

# Generate prompt
jj log --ignore-working-copy --no-graph --color always -r @ -T '
    surround(
        " (",
        ")",
        separate(
            " ",
            bookmarks.join(", "),
            coalesce(
                surround(
                    "\"",
                    "\"",
                    if(
                        description.first_line().substr(0, 16).starts_with(description.first_line()),
                        description.first_line().substr(0, 16),
                        description.first_line().substr(0, 15) ++ "…"
                    )
                ),
                label(if(empty, "empty"), "?")
            ),
            change_id.shortest(),
            if(conflict, label("conflict", "(!)")),
            if(empty, label("empty", "(e)")),
            if(divergent, "(⑂)"),
            if(hidden, "(h)"),
        )
    )
'