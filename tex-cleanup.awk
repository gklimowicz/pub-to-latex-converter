# Eliminate cleanup items that were too difficult to do in the conversion script.

# Eliminate blank lines before any \\end{}

BEGIN {
     in_block = 0;
     have_blank_line = 0;
}

/\\begin{/ {
     in_block++;
     have_blank_line = 0;
     print;
     next;
}

/^\\(chapter|section|subsection|subsubsection|paragraph|subparagraph|begin)/ {
     # print "Delete blank line before " NR ":" $0 >"/dev/stderr";
     have_blank_line = 0;
     print;
     next;
}

in_block && /\\end{/ {
     # print "Delete blank line before " NR ": " $0 >"/dev/stderr";
     have_blank_line = 0;
     in_block--;
     print;
     next;
}

/\\end{/ {
     in_block--;
     if (in_block < 0) {
          print NR ": excessive \\end ignored." >"/dev/stdout";
          in_block = 0;
     }
}

/^[ \t]*$|^\\par$|^\\par\\par$|^\\\\$/ {
     have_blank_line++;
     next;
}


have_blank_line {
     print "";
     have_blank_line = 0;
     print;
     next;
}

{
     print;
     next;
}

END {
}
