all: run_biosfix.sh

clean:
	rm -f run_biosfix.sh payload.tar.gz

run_biosfix.sh: decompress payload.tar.gz Makefile
	cat decompress payload.tar.gz > $@

payload.tar.gz: biosfix/biosfix_data.tar.gz biosfix/biosfix.sh Makefile
	tar czvf $@ biosfix
