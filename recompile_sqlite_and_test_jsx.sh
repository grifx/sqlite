#!/bin/bash
./configure --enable-load-extension
make
./sqlite3 -echo :memory: < experiment/test_jsx.sql