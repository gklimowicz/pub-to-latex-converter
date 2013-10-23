pub-to-latex-converter
======================

Awk program used to convert from old PUB format "A Computational Logic" to LaTeX for Boyer and Moore.

# History
This awk program was used to convert an old copy of the book _A Computational Logic_ from the original PUB format to LaTeX. The copyright for _A Computational Logic_ reverted back to the original authors some time ago, but couldn't be viewed as there are no appropriate PUB formatters available these days. (At least, we couldn't find one.)

I took an old description of the PUB format, the original copy of the book and a lot of guidance from Drs. Moore, Boyer and Matt Kaufmann to produce something that was a reasonable starting point for hand cleanup.

The final document, modified by Matt I believe, is available on Dr. Boyer's web site at http://www.cs.utexas.edu/users/boyer/publications.html.

I have not included the original PUB source code, as I don't have the rights to it and don't want to interfere in any way with the original authors.

# Usage
The Makefile is straightforward. Assuming you have the original acl.txt file, a simple _make_ will generate the acl.tex output.

# Annoyances
There is a lot of awk that is geared to the handling of the ASCII art for trees and such. This limits its usefulness.

I don't really know either PUB or LaTeX, so the translations are not idiomatic. The final version created by Dr. Kaufmann is much better.

# Acknowledgements
I wish to thank Dr. J Moore, Dr. Bob Boyer and Dr. Matt Kaufmann for the opportunity to work on this. It was fun and seemed to be somewhat useful for them.

I also appreciate the fine TeXShop software package that we rely on here for the LaTeX to PDF conversion.


Gary Klimowicz
2013-10-22
