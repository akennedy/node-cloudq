mongo = require 'mongoskin'
_ = require 'underscore'


module.exports = 
  name: 'q-mongodb'
  # establish db connection
  # ---
  # param: db                -  Database Connection URL 
  # param: collection_name   -  Name of Cloudq Collection (Defaults cloudq.jobs)
  init: (done) ->
    # Init MongoDb
    @db = mongo.db(process.env.MONGOSVR or 'localhost:27017/cloudq')
    @jobs = @db.collection('cloudq.jobs')
    done()

  attach: (options) ->
    # queue job
    # ---
    # param: name   - Name of Queue
    # param: job    - Job Object
    # param: cb     - callback 
    @queueJob = (name, job, cb) ->
      _.extend job, 
        queue: name
        queue_state: @QUEUED
        inserted_at: new Date()
      @jobs.insert job, cb

    # reserve job for processing
    # ---
    # param: name    - Name of Queue
    # param: cb      - Callback
    @reserveJob = (name, cb) ->
      @jobs.findAndModify(
        {queue: name, queue_state: @QUEUED }
        , [['inserted_at', 'ascending']]
        , {$set: {queue_state: @RESERVED, updated_at: new Date() }}
        , {new: true }
        cb
      )

    # remove job
    # ---
    # param: job_id    - id of job to remove
    # param: cb        - callback  
    @removeJob = (job_id, cb) -> @jobs.removeById job_id, cb
  
    # jobs by queue by state
    # ---
    # param: cb        - callback
    @groupJobs = (cb) ->
      @jobs.group ['queue','queue_state'], {}, {"count":0}, "function(obj,prev){ prev.count++; }", true, cb
    