require 'formula'

def mysql_installed?
  `which mysql_config`.length > 0
end

class Php52 <Formula
  url 'http://jp2.php.net/get/php-5.2.17.tar.gz/from/jp.php.net/mirror'
  homepage 'http://php.net/'
  md5 '04d321d5aeb9d3a051233dbd24220ef1'
  version '5.2.16'

  # So PHP extensions don't report missing symbols
  skip_clean ['bin', 'sbin']


  depends_on 'libxml2'
  depends_on 'jpeg'
  depends_on 'libpng'
  depends_on 'mcrypt'
  depends_on 'gettext'
  if ARGV.include? '--with-mysql'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
  if ARGV.include? '--with-mysql55'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
  if ARGV.include? '--with-pgsql'
    depends_on 'postgresql'
  end
  if ARGV.include? '--with-mssql'
    depends_on 'freetds'
  end
  
  def options
   [
     ['--with-mysql', 'Include MySQL support'],
     ['--with-mysql55', 'Include MySQL 5.5 support'],
     ['--with-pgsql', 'Include PostgreSQL support'],
     ['--with-mssql', 'Include MSSQL-DB support'],
     ['--with-apache', 'Build shared Apache 2.0 Handler module'],
   ]
  end

  def patches
   DATA
  end
  
  def configure_args
    args = [
      "--prefix=#{prefix}",
      "--with-config-file-path=#{prefix}/etc",
      "--with-iconv-dir=/usr",
      "--enable-exif",
      "--enable-soap",
      "--enable-sqlite-utf8",
      "--enable-wddx",
      "--enable-ftp",
      "--enable-sockets",
      "--enable-zip",
      "--enable-pcntl",
      "--enable-shmop",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--enable-sysvmsg",
      "--enable-mbstring",
      "--enable-mbregex",
      "--enable-bcmath",
      "--enable-calendar",
      "--enable-zend-multibyte",
      "--with-openssl=/usr",
      "--with-zlib=/usr",
      "--with-bz2=/usr",
      "--with-ldap",
      "--with-ldap-sasl=/usr",
      "--with-xmlrpc",
      "--with-iodbc",
      "--with-kerberos=/usr",
      "--with-libxml-dir=#{Formula.factory('libxml2').prefix}",
      "--with-xsl=/usr",
      "--with-curl=/usr",
      "--with-gd",
      "--with-snmp=/usr",
      "--enable-gd-native-ttf",
      "--with-mcrypt=#{Formula.factory('mcrypt').prefix}",
      "--with-jpeg-dir=#{Formula.factory('jpeg').prefix}",
      "--with-png-dir=#{Formula.factory('libpng').prefix}",
      "--with-gettext=#{Formula.factory('gettext').prefix}",
      "--mandir=#{man}",
      "--program-suffix=52"
    ]

    # Free type support
    if File.exist? "/usr/X11"
      args.push "--with-freetype-dir=/usr/X11"
    end

    # Build Apache module
    if ARGV.include? '--with-apache'
      args.push "--with-apxs2=/usr/sbin/apxs"
      args.push "--libexecdir=#{prefix}/libexec"
    end

    if ARGV.include? '--with-mysql'
      args.push "--with-mysql=#{Formula.factory('mysql').prefix}"
      args.push "--with-pdo-mysql=#{Formula.factory('mysql').prefix}"
    end

    if ARGV.include? '--with-mysql55'
      args.push "--with-mysql=#{Formula.factory('mysql55').prefix}"
      args.push "--with-pdo-mysql=#{Formula.factory('mysql55').prefix}"
    end

    if ARGV.include? '--with-pgsql'
      args.push "--with-pgsql=#{Formula.factory('postgresql').prefix}"
      args.push "--with-pdo-pgsql=#{Formula.factory('postgresql').prefix}"
    end

    if ARGV.include? '--with-mssql'
      args.push "--with-mssql=#{Formula.factory('freetds').prefix}"
    end

    return args
  end
  
  def install

    ENV.O3 # Speed things up
    system "./configure", *configure_args

    if ARGV.include? '--with-apache'
      # Use Homebrew prefix for the Apache libexec folder
      inreplace "Makefile",
        "INSTALL_IT = $(mkinstalldirs) '$(INSTALL_ROOT)/usr/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='$(INSTALL_ROOT)/usr/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so",
        "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so"
    end
    
    system "make"
    system "make install"

    system "cp ./php.ini-recommended #{prefix}/etc/php.ini"

    if ARGV.include? '--main'
      system "ln -s /usr/local/bin/php52 /usr/local/bin/php"
    end
  end

 def caveats; <<-EOS
   For 10.5 and Apache:
    Apache needs to run in 32-bit mode. You can either force Apache to start 
    in 32-bit mode or you can thin the Apache executable.
   
   To enable PHP in Apache add the following to httpd.conf and restart Apache:
    LoadModule php5_module    #{prefix}/libexec/apache2/libphp5.so

    The php.ini file can be found in:
      #{prefix}/etc/php.ini
   EOS
 end


 def startup_plist; <<-EOPLIST.undent
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
     <key>Label</key>
     <string>org.php.php-fpm</string>
     <key>Program</key>
     <string>#{sbin}/php-fpm</string>
     <key>RunAtLoad</key>
     <true/>
   </dict>
   </plist>
   EOPLIST
 end
end

__END__
