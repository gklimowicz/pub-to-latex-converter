BEGIN {
     the_line = "";
}

function flush_line() {
     if (the_line != "")
          print the_line;
     the_line = "";
}

/^\. / {
     sub(/^\.  */, "");
     the_line = the_line " " $0;
     next;
}

/^ *$/{
     flush_line();
     print;
     next;
}

{
     flush_line();
     the_line = $0;
}

END {
     flush_line();
}
