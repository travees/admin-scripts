#!/bin/bash
#
# Generate OpenSSL CSR with multiple configs selected from a menu
#
# Copyright (C) 2015  Travis Foster <travees@ddv.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

#
# Show menu
#

cat <<EOL
Select company:
1) Company
2) Company

EOL
echo -n "Number [1]: "

read company

#
# Shared config
#

# Department
_OU="IT"
# Country code
_C="US"
# State
_ST="California"
# City
_L="Pasadena" 


#
# Custom config
# Override shared config based on menu selection
#

case $company in
    2)
        _O="Company Name 1"
        ;;
    1 | *)
        _O="Company Name 2"
        ;;
esac

#
# Write config to tmp file
#

CONFFILE=/tmp/gencsr.$$
cat <<@eof >$CONFFILE
[req] # openssl req params
prompt = no
distinguished_name = dn-param
[dn-param] # DN fields
O = $_O
OU = $_OU
C = $_C
ST = $_ST
L = $_L
CN = $1
@eof

#
# Generate CSR
#

openssl req -config $CONFFILE -newkey rsa:2048 -new -nodes -keyout $1.key -out $1.csr
rm -f $CONFFILE
