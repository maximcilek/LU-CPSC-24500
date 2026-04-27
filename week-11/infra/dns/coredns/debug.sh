
sudo nerdctl inspect coredns
sudo nerdctl logs coredns
sudo nerdctl rm -f coredns
sudo nerdctl run --rm --net prod-net docker.io/library/busybox ping etcd
sudo nerdctl logs -f coredns
dig @127.0.0.1 example.org
"""
; <<>> DiG 9.18.39-0ubuntu0.24.04.3-Ubuntu <<>> @127.0.0.1 example.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 21721
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: d081d6a6ce2f2f7c (echoed)
;; QUESTION SECTION:
;example.org.                   IN      A

;; AUTHORITY SECTION:
.                       28      IN      SOA     ns.dns. hostmaster. 1777161247 7200 1800 86400 30

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Sat Apr 25 18:54:09 CDT 2026
;; MSG SIZE  rcvd: 103

"""