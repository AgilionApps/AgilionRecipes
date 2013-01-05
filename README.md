# AgilionRecipes

Agilion Chef recipes, for use with librarian. Particularly useful for local development with vagrant.

To generate a new rails application from template simply execute (interactive):

```shell
rails new AppName -d postgresql -T -m https://i.dont.know.url.yet
```

This will create the application, set up vagrant and chef, boot the vm, provision the vm, and provide custom post-install steps.
