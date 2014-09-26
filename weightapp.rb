require 'sinatra'
require 'slim'

get('/') { slim :index }

__END__

@@layout
doctype html 
html
  head 
    meta charset="utf-8"
    title Just Do It 
    link rel="stylesheet" media="screen, projection" href="/styles.css"
    /[if lt IE 9] 
      script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"
  body 
    h1 Just Do It 
    == yield
 
@@index
h2 My Tasks
ul.tasks
  li Get Milk
