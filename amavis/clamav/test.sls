{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
include:
  - amavis.clamav
  - amavis.diamond
  - amavis.nrpe
  - clamav.nrpe
  - clamav.diamond

test:
  monitoring:
    - run_all_checks
    - wait: 60
    - order: last
