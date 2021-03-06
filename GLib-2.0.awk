#!/usr/bin/awk
#
# Patch the generated wrapper Swift code to handle special cases
#
BEGIN { etpInit = 0 ; vaptrptr = 0 }
/public convenience init.T: ErrorTypeProtocol./ {
	etpInit = 1
	print "    /// Convenience copy constructor, creating a unique copy"
	print "    /// of the passed in Error.  Needs to be freed using free()"
	print "    /// (automatically done in deinit if you use ErrorType)."
}
/self.init.other.ptr./ {
	if (etpInit) {
		print "	self.init(g_error_copy(other.ptr))"
		etpInit = 0
		next
	}
}
/no reference counting for GError, cannot ref/ { next }
/no reference counting for GError, cannot unref/ {
	print "	    g_error_free(error_ptr)"
	next
}
/ -> GIConv {/, /^}/ {
	sub(/GIConv {/,"GIConv? {")
	sub(/return rv/,"return rv == unsafeBitCast(-1, to: GIConv.self) ? nil : rv")
}
/UnsafeMutablePointer.CVaListPointer/ {
	vaptrptr = 1
	print "#if !os(Linux)"
}
/^$/ {
	if (vaptrptr) {
		print "#endif"
		vaptrptr = 0
	}
}
/\/\/\// {
	if (vaptrptr) {
		print "#endif"
		vaptrptr = 0
	}
}
// { print }
