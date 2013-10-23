function dprint(str) {
     print str >>"/dev/stderr";
}

function reset_state_variables() {
     in_title = 0; in_authors = 0; in_chapter = 0;
     in_asis = 0; in_crown = 0;
     in_bullet = 0; in_bullet_need_item = 0;
     in_quotes = 0; in_block = 0; in_special_paths_block = 0;
     in_underline = 0; in_center = 0; in_open_brace = 0;
     in_starrs = 0;
     in_add_shell_fixup = 0; done_add_shell_fixup = 0;
     elide_blank_lines = 0;
}

function to_title_case(str,    __arr, __n, __i) {
     __n = split(str, __arr);
     for (__i = 1; __i <= __n; __i++) {
          if (length(__arr[__i]) == 1) {
               __arr[__i] = toupper(substr(__arr[__i],1,1));
          } else {
               __arr[__i] = toupper(substr(__arr[__i],1,1)) \
                    tolower(substr(__arr[__i], 2, length(__arr[__i])-1));
          }
     }
     str = __arr[1];
     for (__i = 2; __i <= __n; __i++)
          str = str " " __arr[__i];
     gsub(/ A /, " a ", str);
     gsub(/ An /, " an ", str);
     gsub(/ And /, " and ", str);
     gsub(/ As /, " as ", str);
     gsub(/ For /, " for ", str);
     gsub(/ Of /, " of ", str);
     gsub(/ Or /, " or ", str);
     gsub(/ Our /, " our ", str);
     gsub(/ The /, " the ", str);
     gsub(/ To /, " to ", str);
     return str;
}

function start_chapter(sectype, title, cn) {
     if (sectype == "appendix") {
          force_appendix();
     } else if (sectype == "chapter") {
          force_mainmatter();
     } else {
          # frontmatter; do nothing as we're already there
          ;
     }
     print "\\chapter{" title "}";
     # print "\\pagestyle{headings}";
     # dprint(NR ": Start " sectype " <<" cn ">> title <<" title ">>");
}

function force_mainmatter() {
     if (!seen_mainmatter) {
          print "\\mainmatter";
          seen_mainmatter = 1;
     }
}

function force_appendix() {
     if (!seen_appendix) {
          print "\\appendix";
          seen_appendix = 1;
     }
}

function force_backmatter() {
     if (!seen_backmatter) {
          print "\\backmatter";
          seen_backmatter = 1;
     }
}

function push_format(command_line,      __crown) {
     __crown = $0;
     gsub(/[0-9]*(\(.*\))*/, "", __crown);
     nested_formats[nest_depth++] = __crown;
}

function pop_format() {
     return nested_formats[--nest_depth];
}

BEGIN {
     print "\\documentclass[11pt]{book}";
     print "\\usepackage[USenglish]{babel}";
     print "\\setlength\\textwidth{4.5in}";
     print "\\setlength\\oddsidemargin{1in}";
     print "\\setlength\\evensidemargin{1in}";
     print "\\setlength\\marginparwidth{0in}";
     print "\\setlength\\marginparsep{0in}";
     print "\\setlength\\textheight{7.5in}";
     print "\\setcounter{tocdepth}{1}";
     print "\\newenvironment{pubasis}{\\begin{flushleft}\\ttfamily\\small}{\\normalsize\\rmfamily\\end{flushleft}}";
     print "\\newenvironment{pubcrown}{\\begin{quote}}{\\end{quote}}";
     print "\\newenvironment{pubbullet}{\\begin{enumerate}}{\\end{enumerate}}";
     print "\\newenvironment{publist}{\\begin{enumerate}}{\\end{enumerate}}";
     print "\\newtheorem{path}{Path}";
     print "\\newcommand{\\axiomordefinition}[1]{\\vspace{6pt}\\texttt{\\textbf{#1}}}";
     print "\\newcommand{\\pubinlineunderline}[1]{\\emph{#1}}";
     print "\\newcommand{\\pubdefaulttextsize}{\\large}";
     print "\\hyphenation{the-o-rem}";
     print "\\begin{document}";
     print "\\frontmatter";
     print "\\thispagestyle{empty} \\vspace*{1.25in}";
     print "\\LARGE \\textbf{A Computational Logic} \\normalsize";
     print "\\newpage \\thispagestyle{empty} \\vspace*{5.5in}";
     print "\\begin{flushleft}This is a volume in the\\\\";
     print "ACM MONOGRAPH SERIES\\\\";
     print "\\vspace{\\baselineskip}Editor: THOMAS A. STANDISH, \\emph{University of California at Irvine}\\\\";
     print "\\vspace*{2\\baselineskip}A complete list of titles in this series appears at the end of this volume.\\end{flushleft}";
     seen_backmatter = 0; seen_mainmatter = 0;
     seen_appendix = 0; seen_bibliography = 0;
     chapter_title = ""; section_title = ""; subsection_title = "";
     nested_formats[0] = "";
     nest_depth = 0;
     reset_state_variables();
}

elide_blank_lines && /^ *$/ {
     # Eat blank lines after important things begin
     next;
}

elide_blank_lines && /^[^.]/ {
     # We see a non-blank non-command line. We're done eating blank lines.
     elide_blank_lines = 0;
}

in_chapter && !elide_blank_lines && /^ *$/ {
     # Keep this blank line but eat subsequent blank lines
     elide_blank_lines = 1;
}

/^.REQUIRE/ {next;}

/^.SEND TITLEPAGE/ {in_title = 1; next;}
in_title && /^ *$/ {next;}
in_title && /^.CENTER|^.BEGIN/ {next;}
in_title && /^.SKIP/ {next};
in_title && /^[A-Z ]*$/ {
     print "\\title{" to_title_case($0) "}";
     next;
}
in_title && /by/ { in_title = 0; in_authors = 1; next; }

in_authors && /^.SKIPLINES|^.END|^.FLUSH/ {next;}
in_authors && /^ *$/ {next;}
in_authors && /Copyright/ {
     # print "\\author{" $0 "}";
     next;
}
in_authors && /^[a-zA-Z. ]*$/ {
     $0 =  "\\author{" $0 "\\\\SRI International\\\\Menlo Park, California\\\\}";
     # sub(/ and /, " \\and ");
     print;
     next;
}

in_authors && /^\.\)\$/ {
     elide_blank_lines = 1;
     print "\\date{\\begin{flushleft}\\vspace{4in}";
     # print "\\includegraphics{Stacked_AP_Logo.jpg}\\\\";
     print "ACADEMIC PRESS\\\\";
     print "\\small A subsidiary of Harcourt Brace Jovanovich, Publishers\\\\";
     print "New York~~~~London~~~~Toronto~~~~Sydney~~~~San Francisco";
     print "\\end{flushleft}\\nopagebreak}";
     print "\\maketitle";

     print "\\clearpage\\thispagestyle{empty}\\vspace*{1in}";
     print "\\begin{flushleft}\\textsc{Copyright (C) 1979 by Academic Press\\\\";
     print "no part of this publication may be reproduced or\\\\";
     print "transmitted in any form or by any means, electronic\\\\";
     print "or mechanical, including photocoppy, recording, or any\\\\";
     print "information storage and retrieval system, without\\\\";
     print "permission in writing from the publisher.}\\\\";
     print "\\vspace{2\\baselineskip} ACADEMIC PRESS, INC.\\\\";
     print "\\small 111 Fifth Avenue, New York, New York 10003\\normalsize\\\\";
     print "\\vspace{2\\baselineskip} \\emph{United Kindom Edition published by}\\\\";
     print "ACADEMIC PRESS, INC. (LONDON) LTD.\\\\";
     print "\\small 24/28 Oval Road, London NW1  7DX\\normalsize\\\\";
     print "\\vspace{2\\baselineskip}\\small\\textbf{Library of Congress Cataloging in Publication Data}\\\\";
     print "\\vspace{\\baselineskip}";
     print "Boyer, Robert S.\\\\";
     print "~~~~A Computational Logic\\\\";
     print "\\vspace{\\baselineskip}";
     print "~~~~(ACM monographs series)\\\\";
     print "~~~~Includes bibliographic references and index.\\\\";
     print "~~~~1.  Automatic theorem proving.   I.  Moore,\\\\";
     print "J Strother, Date       joint author. II. Title.\\\\";
     print "III. Series:   Association of Computing Machinery.\\\\";
     print "ACM monograph series.\\\\";
     print "QA76.9.A96B68    519.4   79-51693\\\\";
     print "ISBN 0-12-122950-5\\\\";
     print "\\vspace{2\\baselineskip}\\textsc{printed in the united states of america}\\\\";
     print "\\vspace{\\baselineskip}\\footnotesize 79 81 81 82\\ \\ \\ \\ 9 8 7 6 5 4 3 2 1\\normalsize\\end{flushleft}";


     print "\\cleardoublepage\\thispagestyle{empty}\\vspace*{1.2in}\\Large\\begin{flushleft}To our wives,\\\\";
     print "\\vspace{.5\\baselineskip}Anne and Liz\\end{flushleft}";

     print "\\newpage \\thispagestyle{empty} \\newpage\\thispagestyle{empty}";
     print "\\tableofcontents";
     # print "\\thispagestyle{empty}";
     in_authors = 0;
}

!in_authors && /^\.ACKNOWLEDGE \$\($/ {
     in_chapter = 1;
     chapter_title = "Preface"
     start_chapter("frontmatter", chapter_title, "");
     print "\\pubdefaulttextsize";
     elide_blank_lines = 1;
     next;
}

in_chapter && /^\.\)\$$/ {
     in_chapter = 0;
     next;
}

!in_chapter && /^\.SEND ACKNOWLEDGMENTS \$\(/ {
     in_chapter = 1;
     chapter_title = "Preface"
     next;
}

/^\.SEC |^\.SS |^\.SSS |^\.SSSS |^\.SSSSS |^\.APPENDIX/ {
     reset_state_variables();
     in_chapter = 1;
     sec = $0;
     if (sub("\\.SEC +", "", sec)) {
          _sectype = "chapter";
     } else if (sub("\\.SS +", "", sec)) {
          _sectype = "section";
     } else if (sub("\\.SSS +", "", sec)) {
          _sectype = "subsection";
     } else if (sub("\\.SSSS +", "", sec)) {
          _sectype = "subsubsection";
     } else if (sub("\\.SSSSS +", "", sec)) {
          _sectype = "paragraph";
     } else if (sub("\\.APPENDIX *", "", sec)) {
          _sectype = "appendix";
     } else {
          _sectype = "unknownsection";
          dprint(NR ": Can't happen: no sub() on <<" sec ">>.");
     }
     # dprint(NR ": Section " _sectype " <<" sec ">>");
     n = split(sec, arr, /,  */);
     # for (i = 1; i <= n; i++) dprint("    " i ": <<" arr[i] ">>");
     gsub(/\|/, "", arr[1]);
     this_title = to_title_case(arr[1]);
     if (this_title == "Index")
          force_backmatter();

     if (n == 1) {
          this_name = tolower(arr[1]);
          label_name = "";
     } else {
          sub(/:/, "", arr[2]);
          label_name = arr[2];
          this_name = tolower(arr[2]);
     }
     if (_sectype == "chapter" || _sectype == "appendix") {
          start_chapter(_sectype, this_title, this_name);
     } else {
          print "\\" _sectype "{" this_title "}";
     }
     if (label_name != "")
          print "\\label{" label_name "}";
     print "\\pubdefaulttextsize";
     elide_blank_lines = 1;

     # Record our current chapter, section and subsection naming.
     # This is used at the very end for changing the markup for
     # better aesthetics.
     if (_sectype == "chapter" || _sectype == "appendix") {
          chapter_title = this_title;
          section_title = "";
          subsection_title = "";
          subsubsection_title = "";
          paragraph_title = "";
     } else if (_sectype == "section") {
          section_title = this_title;
          subsection_title = "";
          subsubsection_title = "";
          paragraph_title = "";
     } else if (_sectype == "subsection") {
          subsection_title = this_title;
          subsubsection_title = "";
          paragraph_title = "";
     } else if (_sectype == "subsubsection") {
          subsubsection_title = this_title;
          paragraph_title = "";
     } else if (_sectype == "paragraph") {
          paragraph_title = this_title;
     } else {
          dprint(NR ": Can't happen: no such section type <<" _sectype ">> on <<" sec ">>.");
     }
     next;
}

in_chapter && /^\.BEGIN/ {
     in_block = 1;
     elide_blank_lines = 1;
     next;
}

in_chapter && /^\.END *$/ {
     if (!in_block)
          print NR ": .END seen, but not in .BEGIN block." >>"/dev/stderr";
     if (in_special_paths_block)
          print "\\end{path}";
     if (in_center)
          print "\\end{center}";
     in_block = 0;
     in_special_paths_block = 0;
     in_center = 0;
     next;
}

in_chapter && /^\.SINGLE SPACE/ {
     next;
}

in_chapter && /^\.NEXT PAGE/ {
     print "\\pagebreak";
     next;
}

in_chapter && /^\.STARRS/ && !in_starrs {
     $0 = "\\par\\pagebreak[0]\\hrulefill\\nopagebreak\\par";
     elide_blank_lines = 1;
     in_starrs = 1;
}

in_chapter && /^\.STARRS/ && in_starrs {
     $0 = "\\nopagebreak\\par\\hrulefill\\nopagebreak\\par";
     # $0 = "}";
     elide_blank_lines = 1;
     in_starrs = 0;
}

in_chapter && /^\.BLANKFIGURE/ {
     # Cheat. there's only one in the document.
     print "\\begin{figure}";
     print "\\vspace{50\\baselineskip}";
     print "\\caption{The Model 0.0}";
     print "\\end{figure}";
     next;
}

in_block && /^\.CENTER/ {
     print "\\begin{center}";
     in_center = 1;
     next;
}

in_block && /^\.INDENT/ {
     # print NR ": TODO handle " $0 >>"/dev/stderr";
     in_special_paths_block = 1;
     next;
}

in_block && in_special_paths_block && /^ *$/ {
     print "\\end{path}";
     next;
}

in_block && in_special_paths_block && /^Path [0-9]:/ {
     # Special handling of path list in "The Paths Through FSTRPOS"
     sub(/^Path [0-9]:##/, "\\begin{path}");
     elide_blank_lines = 1;
}

in_chapter && /^\.ASIS/ {
     push_format($0);
     $0 = "\\begin{pubasis}";
     in_asis = 1;
     elide_blank_lines = 1;
     # Note that we might want to adjust this \\begin later, based on where we saw it.
     # next;
}

in_chapter && /^\.BULLET/ {
     push_format($0);
     $0 = "\\begin{pubbullet}";
     print;
     # print "\\item";
     in_bullet = 1;
     in_bullet_need_item = 1;
     elide_blank_lines = 1;
     next;
}

in_chapter && /^\.CROWN/ {
     push_format($0);
     $0 = "\\begin{pubcrown}";
     in_crown = 1;
     elide_blank_lines = 1;
     # next;
}

in_chapter && /^\.LIST/ {
     push_format($0);
     $0 = "\\begin{publist}";
     in_bullet = 1;
     elide_blank_lines = 1;
     # next;
}

in_chapter && /^\.ITEM/ {
     in_bullet_need_item = 1;
     next;
}

function close_format(format) {
     if (format == ".ASIS") {
          $0 = "\\end{pubasis}";
          in_asis = 0;
     } else if (format == ".BULLET") {
          $0 = "\\end{pubbullet}";
          in_bullet = 0;
          in_bullet_need_item = 0;
     } else if (format == ".CROWN") {
          $0 = "\\end{pubcrown}";
          in_crown = 0;
     } else if (format == ".LIST") {
          $0 = "\\end{publist}";
          in_bullet = 0;
          in_bullet_need_item = 0;
     }
}

in_chapter && /^\.ENDASIS/ {
     prev_format = pop_format();
     if (prev_format != ".ASIS") {
          print NR ": Incorrect nesting: " prev_format " closed by .ENDASIS" >>"/dev/stderr";
     }
     close_format(prev_format);
     # next;
}

in_chapter && /^\.ENDBULLET/ {
     prev_format = pop_format();
     if (prev_format != ".BULLET") {
          print NR ": Incorrect nesting: " prev_format " closed by .ENDBULLET" >>"/dev/stderr";
     } else {
          in_bullet = 0;
          in_bullet_need_item = 0;
     }
     close_format(prev_format);
     # next;
}

in_chapter && /^\.ENDCROWN/ {
     prev_format = pop_format();
     if (prev_format != ".CROWN") {
          print NR ": Incorrect nesting: " prev_format " closed by .ENDCROWN" >>"/dev/stderr";
     }
     close_format(prev_format);
     # next;
}

in_chapter && /^\.ENDLIST/ {
     prev_format = pop_format();
     if (prev_format != ".LIST") {
          print NR ": Incorrect nesting: " prev_format " closed by .ENDLIST" >>"/dev/stderr";
     } else {
          in_bullet = 0;
          in_bullet_need_item = 0;
     }
     close_format(prev_format);
     # next;
}

in_bullet && /^ *$/ {
     # print "\\item";
     in_bullet_need_item = 1;
     next;
}

in_bullet && in_bullet_need_item && /^[^.]/ {
     sub(/   */, "");
     $0 = "\\item " $0;
     in_bullet_need_item = 0;
}

/^\.ALLREFS/ {
     force_backmatter();
     in_chapter = 1;
     seen_bibliography = 1;
     # print "\\include{thebibliography}";
     print "\\cleardoublepage";
     print "\\addcontentsline{toc}{chapter}{Bibliography}";
     print "\\begin{thebibliography}{99}";
     next;
}

/^\.REFER +[A-Z0-9]+, *\|.*\|/ {
     $0 = gensub(/\.REFER +([A-Z0-9]+), *\|(.*)\|/, "\\\\bibitem{\\1} \\2", "g");
}

/^\.ENDREFS/ {
     print "\\end{thebibliography}"
     in_chapter = 0;
     in_bibliography = 0;
     next;
}

/^\.STANDARD +BACK/ {
     force_backmatter();
     print "\\end{document}";
     next;
}

# From here, repeatedly transform $0 to appropriate form.

# Start with free-floating characters that can also appear in TeX
# ~ is used to mark equations; replace with *, as that's what's in the book.
in_chapter && /~/ {
     gsub(/~/, "*");
}

# Replace $a^ with uparrows; these are used to mark positions
# in strings when describing string search.
in_chapter && /\$[aA]\^/{
     gsub(/\$[aA]\^/, "$\\uparrow$");
}

# Next, get rid of curly braces. These show up as $a{
# closed by both $a} and plain }. Note that the close may not
# be on the same line as the open.
in_chapter && /\$[Aa]}/ {
     gsub(/\$[Aa]}/, "}");
}

in_chapter && /\$[Aa]{[^}]*}/ {
     # dprint(NR ": Found $A{.*} in <<" $0 ">>");
     $0 = gensub(/\$[Aa]{([^}]*)}/, "\\\\{\\1\\\\}", "g");
     gsub(/\$[aA]}/, "\\}");
     # dprint("                     $0 now <<" $0 ">>");
}

#    (1) Find isolated $a{ and then look for close.
in_chapter && /\$[aA]{[^$}]*$/ {
     in_open_brace = 1;
     sub(/\$[aA]{/, "\\{");
}

#    (2) In open brace, looking for close
in_chapter && in_open_brace && /}/ {
     in_open_brace = 0;
     sub(/}/, "\\}");
}

in_chapter && /{YONSEC  *[A-Z]+}/ {
     # dprint(NR ": Found YONSEC: " $0);
     $0 = gensub(/{YONSEC  *([A-Z]+)}/, "Chapter~\\\\ref{\\1}", "g");
}

in_chapter && /{YONSS  *[A-Z]+}/ {
     # dprint(NR ": Found YONSS: " $0);
     $0 = gensub(/{YONSS  *([A-Z]+)}/, "section~\\\\ref{\\1}", "g");
}

in_chapter && /{APP +[A-Z0-9]+}/ {
     # dprint(NR ": Found REF " $0);
     $0 = gensub(/{APP  *([A-Z0-9]+)}/, "Appendix~\\\\ref{\\1}", "g");
}

in_chapter && /{REF +[A-Z0-9]+}/ {
     # dprint(NR ": Found REF " $0);
     $0 = gensub(/{REF  *([A-Z0-9]+)}/, "\\\\cite{\\1}", "g");
}

in_chapter && /{FNOTE *.*}/ {
     # dprint(NR ": Found REF " $0);
     gsub(/{FNOTE */, "\\footnote{");
     gsub(/\|/, "");
}

/{SECTIONORCHAPTER}/ {
     gsub(/{SECTIONORCHAPTER}/, "chapter");
}

/{SUBSECTIONORSECTION}/ {
     gsub(/{SUBSECTIONORSECTION}/, "section");
}

in_asis && /STR:/ {
     gsub(/_/, " ");
     gsub(/[A-Za-z][A-Za-z. ]*$/, "\\verb*+&+");
     # Note that we have to fixup these spaces in the match string later
     $0 = gensub(/([A-Za-z.]) /, "\\1%", "g");
}

in_chapter && /__[^_]*_/ {
     # dprint(NR ": Found <<__.*_>>");
     $0 = gensub(/__([^_]*)_/, "\\\\pubinlineunderline{\\1}", "g");
}

in_chapter && /__/ {
     # dprint(NR ": Found isolated __");
     sub(/__/, "\\pubinlineunderline{");
     in_underline = 1;
}

in_chapter && in_underline && /_/ {
     in_underline = 0;
     sub(/_/, "}");
}

in_chapter && /'_'/ {
     gsub(/'_'/, "`\\verb*+ +'");
}

in_chapter && / _ / {
     gsub(/ _ /, " \\_ ");
}

in_chapter && /#/ {
     gsub(/#/, "~");
}

in_chapter && /=\$[Mm]-1\// {
     gsub(/=\$[Mm]-1\//, "$\\neq$");
}

in_chapter && /\/\$[Mm]-1=/ {
     gsub(/\/\$[Mm]-1=/, "$\\neq$");
}

in_chapter && /<\$[Mm]-1_/ {
     gsub(/<\$[Mm]-1_/, "$\\leq$");
}

in_chapter && /_\$[Mm]-1</ {
     gsub(/_\$[Mm]-1</, "$\\leq$");
}

in_chapter && />\$[Mm]-1_/ {
     gsub(/>\$[Mm]-1_/, "$\\geq$");
}

in_chapter && /_\$[Mm]-1>/ {
     gsub(/_\$[Mm]-1>/, "$\\geq$");
}

in_chapter && /:\$[Mm]-1-/ {
     gsub(/:\$[Mm]-1-/, "$\\div$");
}

in_chapter && /<->/ {
     gsub("<->", "$\\leftrightarrow$");
}

in_chapter && /->/ {
     gsub("->", "$\\rightarrow$");
}

in_chapter && /</ {
     gsub(/</, "$\\langle$");
}

in_chapter && />/ {
     gsub(/>/, "$\\rangle$");
}

# &[...] subscripts
in_chapter && /[-a-z1-9A-Z]*\[&[^]]*\]/ {
     $0 = gensub(/([-a-z1-9A-Z]*)\[&([^]]*)\]/, "$\\1_{\\2}$", "g");
}

# {SUB ...} subscripts
in_chapter && /{SUB "[-a-z1-9A-Z]*"\\?}/ {
     $0 = gensub(/{SUB "([-a-z1-9A-Z]*)"\\?}/, "_{\\1}", "g");
}

in_chapter && /[+a-zA-Z0-9]+\^\^[a-zA-Z0-9]+\^/ {
     # dprint(NR ": Found <<^^.*^>>");
     $0 = gensub( /([a-zA-Z0-9+]+)\^\^([a-zA-Z0-9]+)\^/ , "$\\1^{\\2}$", "g");
}

in_chapter && /D\^n/ {
     # dprint(NR ": Found <<D^n>>");
     $0 = gensub( /D\^n/ , "$D^{n}$", "g");
}

in_chapter && /p & q/ {
	gsub(/p & q/, "p \\\\\\& q");
}

in_chapter && /} & / {
	gsub(/} & /, "} \\\\\\& ");
}

in_chapter && /\.\.\./ {
	gsub(/\.\.\./, "\\ldots{}");
}

in_chapter && /\$\$/ {
     gsub(/\$\$/, " ");
}

in_chapter && /"/ {
     if (in_quotes) {
          sub(/"/, "''");
          in_quotes = 0;
     }
     $0 = gensub(/"([^"]*)"/, "``\\1''", "g");
     if ($0 ~ /"/) {
          sub(/"/, "``");
          in_quotes = 1;
     }
}

/\[Claim/ {
     sub(/\[/, "{[}");
     sub(/\]/, "{]}");
}

# space expansion in .ASIS
in_asis && / / {
     gsub(/ /, "~");
     # Second half of formatting STR: ..... correctly.
     gsub(/%/, " ");
}

# Replace \ in .ASIS with $\backslash$. These are used for drawing trees
in_asis && /\\$/{
     gsub(/\\$/, "$\\backslash$");
}

# Replace / in .ASIS with $/$ when these are used for drawing trees
in_asis && /~~~\/~~/{
     gsub(/~~~\/~~/, "~~~$/$~~");
}

in_asis && !/^[ \t]*$/ && !/\\begin/ && !/\\end/ {
     $0 = $0 "\\\\";
}

in_asis && /^[ \t~]*$/ {
     $0 = "\\par";
}

# Aesthetics
in_asis && /(Axiom|Definition|Theorem)\./ {
     $0 = gensub(/(~~~~~*)(Axiom|Definition|Theorem)\./, "\\1\\\\axiomordefinition{\\2}", "", $0);
     # sub(/\\\\$/, "");
}

# Fix up \par\\ in as-is text.
/\\par\\\\$/ {
     sub(/\\\\$/, "");
}

# Fix up final lines in the Preface to align correctly
in_chapter && chapter_title == "Preface" && /pubasis/ {
     sub(/pubasis/, "tabbing");
}

in_chapter && chapter_title == "Preface" && /~Computer~Science/ {
     sub(/~~*/, "&\\=");
}

in_chapter && chapter_title == "Preface" && !/\\=/ {
     sub(/~~~~~~*/, "\\>");
}

# Fix up footnote references that appear in ASIS blocks
in_asis && /\\footnote/ {
     do {
          _prevstr = $0;
          $0 = gensub(/(footnote[^~]*)~/, "\\1 ", "");
          # dprint($0);
     } while ($0 != _prevstr);
}

# Clean up the first pubasis in the subsection "Inductively Constructed Objects"
in_chapter && subsection_title == "Inductively Constructed Objects" && /begin{pubasis}/ && done_add_shell_fixup == 0 {
     in_add_shell_fixup = 1;
     sub(/pubasis/, "pubcrown");
}

in_chapter && in_add_shell_fixup && /~~~/ {
     gsub(/^~~*/, "");
}

in_chapter && in_add_shell_fixup && /end{pubasis}/ {
     sub(/pubasis/, "pubcrown");
     in_add_shell_fixup = 0;
     done_add_shell_fixup = 1;
}

# Hypenation that can't be done with TeX hyphenation declarations
in_chapter && !/\\ref{/ && !/\\label/ && /[A-Z][A-Z0-9]*\.[A-Z0-9]+/{
     gsub(/ADDTO/, "ADD\\-TO\\-");
     gsub(/ASSIGNMENT/, "ASSIGN\\-MENT");
     gsub(/ASSOCIATIVITY/, "ASSOC\\-IATIV\\-ITY");
     gsub(/ASSUME/, "AS\\-SUME");
     gsub(/CANCELLATION/, "CAN\\-CELLATION");
     gsub(/CHECKER/, "CHECK\\-ER");
     gsub(/COMMUTATIVITY/, "COM\\-MU\\-TA\\-TIV\\-ITY");
     gsub(/COMPLEXITY/, "COM\\-PLEX\\-I\\-TY");
     gsub(/CORRECTNESS/, "CORRECT\\-NESS");
     gsub(/DIFFERENCE/, "DIF\\-FER\\-ENCE");
     gsub(/DISTRIBUTIVITY/, "DIS\\-TRI\\-BU\\-TIV\\-ITY");
     gsub(/DUPLICITY/, "DU\\-PLI\\-CI\\-TY");
     gsub(/FACTOR/, "FAC\\-TOR");
     gsub(/FAC\\-TORIZATION/, "FAC\\-TOR\\-I\\-ZA\\-TION");
     gsub(/FALSIFY/, "FAL\\-SI\\-FY");
     gsub(/FLATTEN/, "FLAT\\-TEN");
     gsub(/GREATEST/, "GREAT\\-EST");
     gsub(/IGNORE/, "IG\\-NORE");
     gsub(/LEFTCOUNT/, "LEFT\\-COUNT");
     gsub(/MAXIMUM/, "MAX\\-I\\-MUM");
     gsub(/NORMALIZE/, "NOR\\-MAL\\-IZE");
     gsub(/REDUNDANT/, "RE\\-DUN\\-DANT");
     gsub(/SINGLETON/, "SINGLE\\-TON");
     gsub(/TAUTOLOGY/, "TAU\\-TOL\\-OGY");
     gsub(/WHILELOOP/, "WHILE\\-LOOP");
     # $0 = gensub(/[A-Z0-9]\.[A-Z]/, "\\1.\\-\\2", "g", $0);
}

# Finally, print the remaining line
in_chapter {
     print;
     next;
}

!in_title && !in_authors && !in_chapter && /^ *$/ {
     next;
}

END {
     close("/dev/stderr");
}
