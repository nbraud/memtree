# Explode { results: [a, b, c], ...foo } into a+foo, b+foo, c+foo
del(.results) as $self | .results[] | . + $self |

# Map each object to the schema expected by Cirrus CI
{
 "path": .file,
 "level": "warning",
 "message": .message,
 "start_line": .line, "end_line": .line,
 "start_column": .column,
 "end_column": .endColumn
}
