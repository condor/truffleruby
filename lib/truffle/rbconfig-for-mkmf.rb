# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 1.0, or
# GNU General Public License version 2, or
# GNU Lesser General Public License version 2.1.

# Split from rbconfig.rb since we need to do expensive tasks like checking the
# clang and opt versions.

require 'rbconfig'

clang = 'clang'
opt = 'opt'

extra_cflags = nil

[clang, opt].each do |tool|
  begin
    version = `#{tool} --version`
  rescue Errno::ENOENT
    raise "#{tool} does not appear to be available - you may need to install LLVM - see doc/user/installing-llvm.md"
  end

  if version =~ /\bversion (\d+\.\d+\.\d+)/
    major, minor, _patch = $1.split('.').map(&:to_i)
    if (major == 3 && minor >= 8) || (major == 4 && minor == 0)
      # OK
    elsif major >= 5
      extra_cflags = '-Xclang -disable-O0-optnone'
    else
      raise "unsupported #{tool} version: #{$1} - see doc/user/installing-llvm.md"
    end
  else
    raise "cannot parse #{tool} version from #{version}"
  end
end

opt_passes = ['-always-inline', '-mem2reg', '-constprop'].join(' ')

debugflags = '-g' # Show debug information such as line numbers in backtrace
warnflags = [
  '-Wimplicit-function-declaration', # To make missing C ext functions clear
  '-Wno-unknown-warning-option',     # If we're on an earlier version of clang without a warning option, ignore it
  '-Wno-int-conversion',             # MRI has VALUE defined as long while we have it as void*
  '-Wno-int-to-pointer-cast',        # Same as above
  '-Wno-unused-value',               # RB_GC_GUARD leaves
  '-Wno-incompatible-pointer-types', # Fix byebug 8.2.1 compile (st_data_t error)
  '-ferror-limit=500'
].join(' ')

cc = clang
cxx = 'clang++'

cflags = "#{debugflags} #{warnflags} -c -emit-llvm"
cflags = "#{extra_cflags} #{cflags}" if extra_cflags
cxxflags = "#{cflags} -stdlib=libc++"

cext_dir = "#{RbConfig::CONFIG['libdir']}/cext"

expanded = RbConfig::CONFIG
mkconfig = RbConfig::MAKEFILE_CONFIG

common = {
  'CC' => cc,
  'CPP' => cc,
  'CXX' => cxx,
  'debugflags' => debugflags,
  'warnflags' => warnflags,
  'CFLAGS' => cflags,
  'CXXFLAGS' => cxxflags
}
expanded.merge!(common)
mkconfig.merge!(common)

mkconfig['COMPILE_C']   = "ruby #{cext_dir}/preprocess.rb $< | $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG) -xc - -o $@ && #{opt} #{opt_passes} $@ -o $@"
mkconfig['COMPILE_CXX'] = "ruby #{cext_dir}/preprocess.rb $< | $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG) -xc++ - -o $@ && #{opt} #{opt_passes} $@ -o $@"

# From mkmf.rb: "$(LDSHARED) #{OUTFLAG}$@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)"
# The only difference is we use linker.rb instead of LDSHARED
mkconfig['LINK_SO'] = "#{RbConfig.ruby} #{cext_dir}/linker.rb -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)"

cflags_for_try_link = "#{debugflags} #{warnflags}"
# From mkmf.rb: "$(CC) #{OUTFLAG}#{CONFTEST}#{$EXEEXT} $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(src) $(LIBPATH) $(LDFLAGS) $(ARCH_FLAG) $(LOCAL_LIBS) $(LIBS)"
mkconfig['TRY_LINK'] = "#{cc} -o conftest $(INCFLAGS) $(CPPFLAGS) #{cflags_for_try_link} #{cext_dir}/ruby.o #{cext_dir}/sulongmock.o $(src) $(LIBPATH) $(LDFLAGS) $(ARCH_FLAG) $(LOCAL_LIBS) $(LIBS)"

%w[COMPILE_C COMPILE_CXX LINK_SO TRY_LINK].each do |key|
  expanded[key] = mkconfig[key].gsub(/\$\((\w+)\)/) { expanded.fetch($1, $&) }
end
