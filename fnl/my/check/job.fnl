(fn process-start [options]
  (let [job (require "plenary.job")]
    (: (job:new options) :start)
    job))


(fn process-kill [fd]
  (when (not (fd:is_closing))
    (fd:close)))


(fn execute-command [bufnr command cwd callback]
  (vim.validate {:bufnr [bufnr :n]
                 :callback [callback :f]})
  (LOG "Executing job" :command command)
  (let [result {:bufnr bufnr :cwd cwd}
        handler (fn [jobid data event]
                  (match event
                    :stdout (set result.stdout data)
                    :stderr (set result.stderr data)
                    _ (do
                        (set result.exit data)
                        (when (not result.stdout)
                          (set result.stdout []))
                        (when (not result.stderr)
                          (set result.stderr []))
                        (callback jobid result))))
        jobid (vim.fn.jobstart
                command {:cwd result.cwd
                         :on_stdout handler
                         :on_stderr handler
                         :on_exit handler
                         :stderr_buffered true
                         :stdout_buffered true})]
    (match jobid
      0 (error "Invalid arguments")
      -1 (error (string.format "Failed to run: %s" (vim.inspect command))))
    jobid))
    
                            
(fn buffer-write [path]
  (let [m vim.bo.modified]
    (set vim.bo.modified false)
    (let [(ok res)
          (pcall
            (fn []
              (vim.cmd
                (.. "silent write " (vim.fn.fnameescape path)))))]
      (set vim.bo.modified m)
      (when (not ok)
        (error res)))))


(fn backup-buffer [bufnr]
  (let [tmpname (vim.fn.tempname)]
   (vim.api.nvim_buf_call bufnr (fn [] (buffer-write tmpname))) 
   tmpname))


(fn slurp [path]
  "Read the file from PATH into a string."
  (match (io.open path "r")
    (nil msg) nil
    f (let [content (f:read "*all")]
        (f:close)
        content)))


(fn get-buffer-lines [bufnr]
  (vim.api.nvim_buf_get_lines
    bufnr 0 (vim.api.nvim_buf_line_count bufnr) true))


(fn send-buffer [jobid bufnr]
  (vim.fn.chansend jobid (get-buffer-lines bufnr))
  (vim.fn.chanclose jobid :stdin))


(fn cancel [jobid]
  (vim.fn.jobstop jobid))


{: execute-command 
 : backup-buffer 
 : slurp 
 : get-buffer-lines 
 : send-buffer 
 : cancel} 
