.SUFFIXES:	.txt .nocont .tex1 .tex .pdf

.txt.nocont:	pub-collapse-continuations.awk Makefile $<
	expand $< | gawk -f pub-collapse-continuations.awk >$@

.nocont.tex1:	pub-to-tex.awk Makefile $<
	gawk -W lint -f pub-to-tex.awk <$< >$@

.tex1.tex:	tex-cleanup.awk Makefile $<
	gawk -W lint -f tex-cleanup.awk <$< >$@

.tex.pdf:
	pdflatex $< && pdflatex $<

all:	acl.tex

acl.tex:	tex-cleanup.awk

acl.tex1:	pub-to-tex.awk

acl.nocont:	pub-collapse-continuations.awk

annotations.txt:	acl.txt Makefile
	(sed -n -e '/^\.[A-Z]/p' acl.txt | sort -u; \
	  sed -e '/[$$]/!d' -e '/$$($$/d' -e '/\.)$$$$/d' \
	      -e 's/}[^$$]*$$/}%$$/g' -e 's/^[^$$]*/$$/' -e 's/}[^$$}]*$$/}/' acl.txt \
	 | tr '%' '\012' | sort; \
	 sed -e '/[{}]/!d' -e 's/}[^{]*{/}%{/g' -e 's/^[^{]*[aj]*{/{/' -e 's/}[^}]*$$/}/' acl.txt \
	 | tr '%' '\012' | sort) >annotations.txt

hyphenations.tex:	acl.txt Makefile
	tr -s ',{}[]\t()0123456789' '                  ' <acl.txt | tr -s ' ' '\012' \
	| sed -e '/^\./d' -e '/\./!d' -e '/\.$$/d' \
	| sed -E -n -e '/^[A-Z0-9.]{5,}$$/p' \
	| tr '.' '\012' \
	| sed -e '/^[0-9]*$$/d' \
	| sort -u \
	| sed -e 's/ADDTO/ADD-TO-/g' -e 's/ASSIGNMENT/ASSIGN-MENT/' \
		-e 's/ASSOCIATIVITY/ASSOC-IATIV-ITY/' \
		-e 's/CANCELLATION/CAN-CELLATION/g' -e 's/COMMUTATIVITY/COM-MU-TA-TIV-ITY/' \
		-e 's/CORRECTNESS/CORRECT-NESS/' \
		-e 's/DIFFERENCE/DIF-FER-ENCE/' \
		-e 's/DISTRIBUTIVITY/DIS-TRI-BU-TIV-ITY/' \
		-e 's/DUPLICITY/DU-PLI-CI-TY/' \
		-e 's/FACTOR/FAC-TOR/' \
		-e 's/FAC-TORIZATION/FAC-TOR-I-ZA-TION/' \
		-e 's/FLATTEN/FLAT-TEN/' \
		-e 's/GREATEST/GREAT-EST/' \
		-e 's/LEFTCOUNT/LEFT-COUNT/' \
		-e 's/MAXIMUM/MAX-I-MUM/' \
		-e 's/SINGLETON/SINGLE-TON/' \
	| sed -e '1s/^/\\hyphenation{/' -e '$$s/$$/}/' >$@

clean:	FRC
	rm -f annotations.txt hyphenations.tex *.aux *.log *.nocont *.pdf *.tex1 *.toc

FRC:

