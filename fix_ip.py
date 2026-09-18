import os
path = "shared_core/lib/services/api_service.dart"
with open(path, "r") as f:
    c = f.read()
c = c.replace("'http://10.0.2.2:3000'", "'http://192.168.1.7:3000'").replace("'http://localhost:3000'", "'http://192.168.1.7:3000'")
with open(path, "w") as f:
    f.write(c)
