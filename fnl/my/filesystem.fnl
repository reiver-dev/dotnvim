(fn slurp [path]
  "Read the file from PATH into a string."
  (match (io.open path "r")
    (nil msg) nil
    f (let [content (f:read "*all")]
        (f:close)
        content)))


(fn spew [path string]
  "Write STRING to file at PATH"
  (match (io.open path "w")
    (nil msg) (error
                (string.format "Failed to write file at `%q`: %s"
                               path msg))
    f (f:write string)))


(local FT_DIRECTORY "directory")
(local FT_FILE "file")
(local FT_UNKNOWN "")

(local EMPTY_STAT
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
                  
(local S_IFMT 0xf000)

(local S_IFBLK 0x6000)
(local S_IFCHR 0x2000)
(local S_IFDIR 0x4000)
(local S_IFREG 0x8000)
(local S_IFIFO 0x1000)
(local S_IFLNK 0xa000)
(local S_IFSOCK 0xc000)

(local S_IFDOOR 0x0)
(local S_IFPORT 0x0)
(local S_IFWHT 0x0)

(local S_ISGID 0x400)
(local S_ISUID 0x800)
(local S_ISVTX 0x200)

;; Read access
(local S_IRUSR 0x100)
(local S_IWUSR 0x080)
(local S_IXUSR 0x040)

;; Group access
(local S_IRGRP 0x020)
(local S_IWGRP 0x010)
(local S_IXGRP 0x008)

;; Other access
(local S_IROTH 0x004)
(local S_IWOTH 0x002)
(local S_IXOTH 0x001)

(local S_IRWXU 0x1c0)
(local S_IRWXG 0x038)
(local S_IRWXO 0x007)

(local S_ENFMT 0x0400)

;; System V aliases
(local S_IREAD 0x100)
(local S_IWRITE 0x080)
(local S_IEXEC 0x40)

(local R (bit.bor S_IRUSR S_IRGRP S_IROTH))
(local W (bit.bor S_IWUSR S_IWGRP S_IWOTH))
(local X (bit.bor S_IXUSR S_IXGRP S_IXOTH))
(local RX (bit.bor R X))
(local RW (bit.bor R W))
(local RWX (bit.bor S_IRWXU S_IRWXG S_IRWXO))

(fn rwx [] (string.format "%x" RWX))


(local allmode
  [:IFBLK S_IFBLK
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


(fn dipairs-iter [array idx]
  (let [a (. array (+ idx 1))
        b (. array (+ idx 2))]
    (when (and (not= nil a) (not= nil b))
      (values (+ idx 2) a b))))


(fn dipairs [array]
  (values dipairs-iter array 0))


(fn stat [path]
  (let [(res msg code) (vim.loop.fs_stat path)]
    (if (not= res nil)
      (values true res)
      (values false msg))))



(fn file? [path]
  (match (stat path)
    (true {:type t}) (= t FT_FILE)
    (false _) false))


(fn mode [path]
  (let [{:mode m} (stat path)]
    (each [i n v e (dipairs allmode)]
      (print n (bit.band v m)))))
    

(fn directory? [path]
  (match (stat path)
    (true {:type t}) (= t FT_DIRECTORY)
    (false _) false))


(fn readable? [path]
  (match (stat path)
    (true {:type t :mode m}) (if (= t FT_DIRECTORY)
                               (bit.band m RX)
                               (bit.band m R))
    (false _) false))
    
    

(fn writable? [path]
  (match (stat path)
    (true {:type t :mode m}) (if (= t FT_DIRECTORY)
                               (bit.band m RWX)
                               (bit.band m RW))
    (false _) false))


{: slurp
 : spew
 : mode
 : file?
 : directory?
 : readable?
 : writable?}
