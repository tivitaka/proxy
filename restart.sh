#!/bin/sh
php run_proxy.php 101 && service 3proxy start && ulimit -n 8192
