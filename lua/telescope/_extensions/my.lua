_T("telescope", "register_extension", {
    exports = {
        manpages = function(opts)
            _T("my.telescope.man", "manpages", opts)
        end,
    },
})

