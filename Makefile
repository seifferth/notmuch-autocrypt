out/notmuch-autocrypt: src/main.sh src/new.sh src/account_init.sh src/account_get.sh src/peer_get.sh src/recommend.sh
	test -d out || mkdir out
	cd src; ../process_includes.sh < main.sh > ../out/notmuch-autocrypt
	chmod +x out/notmuch-autocrypt

.PHONY: clean
clean:
	rm -r out
