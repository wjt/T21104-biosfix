all: run_biosfix.sh

clean:
	rm -f run_biosfix.sh payload.tar.gz

run_biosfix.sh: decompress payload.tar.gz
	cat decompress payload.tar.gz > $@

payload.tar.gz: biosfix_data.tar.gz  biosfix.sh
	tar czvf $@ $^
