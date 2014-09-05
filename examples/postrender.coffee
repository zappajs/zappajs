require('./zappajs') ->

  @locals.title = 'Post-rendering'
  @locals.style = '''
    #quotas div {border: 1px solid #999; background: #eee; padding: 10px; margin: 10px}
    #quotas .highlighted {border: 3px solid #37697e; background: #d0deea}
  '''

  @get '/': ->
    # @user = plan: 'staff'
    @user = plan: 'basic'

    @render 'index', {@user, postrender: 'plans'}

  @postrender plans: ($) ->
    $('.staff').remove() if @user.plan isnt 'staff'
    $('div.' + @user.plan).addClass 'highlighted'

  {h1,div,h2,p,button} = @teacup

  @view index: ->
    h1 'Quotas:'

    div '#quotas', ->
      div '.basic', ->
        h2 'Basic'
        p 'Disk: 1 GB'
        p 'Bandwidth: 10 GB'
        button class: 'staff', -> 'Change Quotas'

      div '.silver', ->
        h2 'Silver'
        p 'Disk: 2 GB'
        p 'RAM: 15 GB'
        button class: 'staff', -> 'Change Quotas'

      div '.golden', ->
        h2 'Golden'
        p 'Disk: 4 GB'
        p 'RAM: 30 GB'
        button class: 'staff', -> 'Change Quotas'

      div '.staff', ->
        h2 'Staff'
        p 'Disk: 10 GB'
        p 'RAM: 100 GB'
