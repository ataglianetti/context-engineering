---
type: Journal
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
---

# [[<% tp.date.now("gggg-[W]ww", 0, tp.file.title)%>|<% tp.date.now("[W]ww", 0, tp.file.title)%>]] | <% tp.date.now("dddd", 0, tp.file.title)%> <% tp.date.now("MMMM", 0, tp.file.title)%> <% tp.date.now("D", 0, tp.file.title)%>, <% tp.date.now("YYYY", 0, tp.file.title)%>

## Log
- <% tp.file.cursor() %>