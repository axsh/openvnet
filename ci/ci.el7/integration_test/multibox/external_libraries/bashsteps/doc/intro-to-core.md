
The motivation for bashsteps is that some scripts can benefit from
putting extra effort up front to have two types of enhancements.  The
first enhancement is to break the script up into meaningful steps.
The second is to write code that can test whether each step has been
done or not.

For some types of scripts (for example very short ones, or
non-destructive, fast executing scripts), it is not worth the effort.
The problem is that often it is not until later that the benefit are
understood for a particular script.  And then the programmer ends up
wishing that the enhancements had been included in the script from the
beginning.

For example, consider this 4 line script (pseudo code):

    git clone some/server
    cd server
    make
    make install

There are many ways to do add the two enhancements to this code.  This
could be done directly with well-placed conditional statements, but
such an over-simplified solution would limit the benefits.  A better
solution might be to use a special framework that can maximize the
benefits of the enhancements (e.g.  dependency analysis, logging,
progress updates, debugging tools, etc.) Unfortunately, using such a
framework requires more upfront effort to understand the
framework(s), choose the framework, install the frameworks, and adapt
the script to the framework.  With either solution, there are real
risks that discourage adding the enhancements in the first place.

The goal of bashsteps is to address these risks.  It is designed to be
extremely easy to get started, have a stable core, and be flexible
enough to choose among various implementations of the framework later.
By keeping everything in bash, dependencies are minimized.

An implementation of the simplest framework for bashsteps is so
simple, it is possible to memorize it:

    : ${prev_cmd_failed:=':'}
    : ${skip_step_if_already_done:=':'}

These two bash variables are all that is needed to do a simple
enhancement of the example script above:

    (  # download
       false
       $skip_if_already_done
       cd /tmp
       git clone some/server
    ) ; $prev_cmd_failed
    
    (  # compile and install
       false
       $skip_if_already_done
       cd /tmp/server
       make
       make install
    ) ; $prev_cmd_failed

At this point, there is no change in functionality, so no benefits
yet.  The purpose here is to illustrate that (at least sometimes)
conversion between an unenhanced script and an enhanced script can be
direct.  The key design choice here is that the code can appear in the
same order as the unenhanced script, as opposed to being split out
into separate functions or separate files. Another related point is
that this design makes it easy to later split steps into multiple
steps, and vise versa.

Now that we have created a couple steps, the lines that can test
whether the step has been done can be inserted:

    (  # download
       [ -d /tmp/some/server ]
       $skip_if_already_done
       cd /tmp
       git clone some/server
    ) ; $prev_cmd_failed
    
    (  # compile and install
       [ -f /usr/bin/serverbin ]
       $skip_if_already_done
       cd /tmp/server
       make
       make install
    ) ; $prev_cmd_failed

Now the script has been enhanced by both splitting it into steps and
by including code that can test whether the step has been done.  With
The above minimal framework, however, the functionality of the script
is still unchanged. 

To start getting benefits, here is a still-quite-simple framework
implementation can be used with the above script:

    : ${prev_cmd_failed:='eval [ $? == 0 ] || exit'}
    : ${skip_step_if_already_done:='eval [ $? == 0 ] && exit'}

Using these definitions, the script can now start to use the tests.
For any step that has been done, the step is automatically skipped,
which can be very beneficial for scripts with steps (such as scripts
that do installation or setup) that tend to be time-consuming or
destructive.

The above is a simple introduction just to the core of bashsteps.
When applying it to realistic examples, limitations have
unsurprisingly been encountered.  At this time a few extensions to
the above have been introduced.  Things are still simple though.  Even if
all the extensions are used, a minimal implementation that lets the
script run with the original functionality can be done with only the
following:

    : ${prev_cmd_failed:=':'}
    : ${starting_step:=':'}
    : ${skip_step_if_already_done:=':'}
    : ${starting_group:=':'}
    : ${skip_group_if_already_done:=':'}

Therefore without downloading or installing any extra code, a bash
programmer can use these constructions at the very early stages of
writing a script.  Then when the actual need for the various
benefits arises, the programmer has the option to find and download
whatever framework implementation can provide the benefits.

And if access to this repository is possible, a modest, well-tested
bashsteps framework implementation can be added to the project to
provide the basic benefits.  This repository also contains an
experimental framework implementation that is implemented as a wrapper
script, so it can instantly add extra features to any script that has been
enhanced with the 5 variables above.
