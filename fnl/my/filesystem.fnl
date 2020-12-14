(module my.filesystem)


(defn slurp [path]
  "Read the file from PATH into a string."
  (match (io.open path "r")
    (nil msg) nil
    f (let [content (f:read "*all")]
        (f:close)
        content)))


(defn spew [path string]
  "Write STRING to file at PATH"
  (match (io.open path "w")
    (nil msg) (error
                (string.format "Failed to write file at `%q`: %s"
                               path msg))
    f (f:write string)))


(def- FT_DIRECTORY "directory")
(def- FT_FILE "file")
(def- FT_UNKNOWN "")

(def- EMPTY_STAT
  {:dev 0
   :mode 0
   :nlink 0
   :uid 0
   :gid 0
   :rdev 0
   :ino 0
   :size 0
   :blksize 0
   :blocks 0
   :flags 0
   :gen 0
   :atime {:sec 0 :nsec 0}
   :mtime {:sec 0 :nsec 0} 
   :ctime {:sec 0 :nsec 0}
   :birthtime {:sec 0 :nsec 0}
   :type ""})
                  
(def- S_IFMT 0xf000)

(def- S_IFBLK 0x6000)
(def- S_IFCHR 0x2000)
(def- S_IFDIR 0x4000)
(def- S_IFREG 0x8000)
(def- S_IFIFO 0x1000)
(def- S_IFLNK 0xa000)
(def- S_IFSOCK 0xc000)

(def- S_IFDOOR 0x0)
(def- S_IFPORT 0x0)
(def- S_IFWHT 0x0)

(def- S_ISGID 0x400)
(def- S_ISUID 0x800)
(def- S_ISVTX 0x200)

;; Read access
(def- S_IRUSR 0x100)
(def- S_IWUSR 0x080)
(def- S_IXUSR 0x040)

;; Group access
(def- S_IRGRP 0x020)
(def- S_IWGRP 0x010)
(def- S_IXGRP 0x008)

;; Other access
(def- S_IROTH 0x004)
(def- S_IWOTH 0x002)
(def- S_IXOTH 0x001)

(def- S_IRWXU 0x1c0)
(def- S_IRWXG 0x038)
(def- S_IRWXO 0x007)

(def- S_ENFMT 0x0400)

;; System V aliases
(def- S_IREAD 0x100)
(def- S_IWRITE 0x080)
(def- S_IEXEC 0x40)

(def- R (bit.bor S_IRUSR S_IRGRP S_IROTH))
(def- W (bit.bor S_IWUSR S_IWGRP S_IWOTH))
(def- X (bit.bor S_IXUSR S_IXGRP S_IXOTH))
(def- RX (bit.bor R X))
(def- RW (bit.bor R W))
(def- RWX (bit.bor S_IRWXU S_IRWXG S_IRWXO))

(defn rwx [] (string.format "%x" RWX))


(def- allmode [:IFBLK S_IFBLK
               :IFCHR S_IFCHR
               :IFDIR S_IFDIR
               :IFREG S_IFREG
               :IFIFO S_IFIFO
               :IFLNK S_IFLNK
               :IFSOCK S_IFSOCK

               :ISGID S_ISGID
               :ISUID S_ISUID
               :ISVTX S_ISVTX

               :IRUSR S_IRUSR
               :IWUSR S_IWUSR
               :IXUSR S_IXUSR

               :IRGRP S_IRGRP
               :IWGRP S_IWGRP
               :IXGRP S_IXGRP

               :IROTH S_IROTH
               :IWOTH S_IWOTH
               :IXOTH S_IXOTH])


(defn- dipairs-iter [array idx]
  (let [a (. array (+ idx 1))
        b (. array (+ idx 2))]
    (when (and (not= nil a) (not= nil b))
      (values (+ idx 2) a b))))

(defn- dipairs [array]
  (values dipairs-iter array 0))


(defn- stat [path]
  (let [(res msg code) (vim.loop.fs_stat path)]
    (if (not= res nil)
      (values true res)
      (values false msg))))



(defn file? [path]
  (match (stat path)
    (true {:type t}) (= t FT_FILE)
    (false _) false))


(defn mode [path]
  (var kk 0)
  (let [{:mode m} (stat path)]
    (each [i n v e (dipairs allmode)]
      (set kk (+ 1 kk))
      (when (< 50 kk)
        (error "LOOP"))
      (print n (bit.band v m)))))
    

(defn directory? [path]
  (match (stat path)
    (true {:type t}) (= t FT_DIRECTORY)
    (false _) false))


(defn readable? [path]
  (match (stat path)
    (true {:type t :mode m}) (if (= t FT_DIRECTORY)
                               (bit.band m RX)
                               (bit.band m R))
    (false _) false))
    
    

(defn writable? [path]
  (match (stat path)
    (true {:type t :mode m}) (if (= t FT_DIRECTORY)
                               (bit.band m RWX)
                               (bit.band m RW))
    (false _) false))
