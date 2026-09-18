import os
path = "backend/src/main.ts"
with open(path, "r") as f:
    c = f.read()
c = c.replace("await app.listen(process.env.PORT ?? 3000);", "await app.listen(process.env.PORT ?? 3000, '0.0.0.0');")
with open(path, "w") as f:
    f.write(c)
