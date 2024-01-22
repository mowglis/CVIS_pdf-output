#
# PDF output PgC
#
PGC = rusek@amos.cvkhk.cz
TARFILE = pdf-output.tar.gz

clean:
	rm -f *.log *.dvi *.aux *.ps > /dev/null 2> /dev/null
get: 
	rsync -Cavuz -e ssh --exclude 'temp/*' $(PGC):~/dokumenty/pdf-output/ .
put:
	rsync -Cavuz -e ssh --exclude 'temp/*' . $(PGC):~/dokumenty/pdf-output
sync: clean get put	
	
