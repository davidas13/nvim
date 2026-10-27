-- LSP file operation methods and their timeout.
return {
    -- timeout when executing LSP client operations
    timeout = 10000,
    -- fully disable/enable file operation methods
    operations = {
        willRename = true,
        didRename = true,
        willCreate = true,
        didCreate = true,
        willDelete = true,
        didDelete = true,
    },
}
