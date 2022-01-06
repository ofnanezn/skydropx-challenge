# skydropx-challenge

This process was almost entirely run in the GCloud CLI that is located in the GCP Console.

Some considerations:
* The project must be billable
* Some environment variables (such as BUCKET_NAME) must be changed, since the names are globally unique in GCP
* The Load Balancer creation was run manually in the GCP GUI because some errors present in the CLI
* Some attributes are stills hardcoded and are not read from environment variables

As mentioned above, the Load Balancer (LB) creation was run manually in the GUI. A brief explanation can be found in the README from the folder *load_balancer_screens*, which also contain pictures of the process.
