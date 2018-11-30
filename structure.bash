#!/bin/bash
APPNAME="SomeCA"
DOMAIN="wpia.local"
ORGANIZATION="Test Environment CA Ltd."
ORGANIZATIONAL_UNIT="Test Environment CAs"
COUNTRY="AT"
KEYSIZE=4096

[ -f config ] && . ./config

STRUCT_CAS=(unassured assured codesign orga orgaSign)
TIME_IDX=(1 2)
points[1]="0101000000Z"
points[2]="0601000000Z"

epoints[1]="0705000000Z"
epoints[2]="0105000000Z"

ROOT_VALIDITY="-startdate 20150101000000Z -enddate 20300101000000Z"
