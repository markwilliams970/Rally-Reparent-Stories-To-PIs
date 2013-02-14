Rally-Reparent-Stories-To-PIs
=============================

The re-parent-stories-to-pis.rb script is a tool to help Rally users bulk
re-parent User Stories to the lowest hierarchy of Portfolio Items.

re-parent-stories-to-pis.rb requires:
- Ruby 1.9.3
- rally_api 0.9.1 or higher
- You can install rally_api and dependent gems by using:
- gem install rally_api

The tool takes a set of User Stories formatted in a CSV
and performs the following functions:
- Bulk re-parents Stories to specified Portfolio Items at the lowest level of PI Hierarchy