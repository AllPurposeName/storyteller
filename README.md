This is a script to add user stories to projects at [The Turing School](http://www.turing.io).

### Usage

#### Running the Task

`rake storyteller *file_name*`

`rake storyteller dinner_dash_setup`

#### Student Setup

[ClassicRichard](https://github.com/ClassicRichard) must be added as a
collaborator before issue label creation can occur.

#### config/application.yml

This application uses Figaro and the ClassicRichard github account. Run `figaro
install` and ask a staff member for the credentials.

#### YAML File Setup

This project parses YAML files to create user stories. The YAML setup looks like
this:

```yml
repositories: https://github.com/AllPurposeName/test-stories, https://github.com/AllPurposeName/test-story
stories:
  issueOne:
    title: Admin can create items
    label: Backlog, Pertinent
    body: >
      Background: I want a new item to need a category

      As an admin

      When I visit "/admin/items/new"

      I can see item creation stuff
```

