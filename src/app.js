const express = require('express');
const promClient = require('prom-client');

const app = express();
app.use(express.json());

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

let tasks = [{ id: 1, title: 'Learn CI/CD', done: false }];

app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/tasks', (req, res) => res.json(tasks));

app.post('/tasks', (req, res) => {
  const task = { id: tasks.length + 1, title: req.body.title, done: false };
  tasks.push(task);
  res.status(201).json(task);
});

app.put('/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id, 10));
  if (!task) return res.status(404).json({ error: 'Task not found' });
  task.done = req.body.done ?? task.done;
  task.title = req.body.title ?? task.title;
  res.json(task);
});

app.delete('/tasks/:id', (req, res) => {
  const before = tasks.length;
  tasks = tasks.filter(t => t.id !== parseInt(req.params.id, 10));
  if (tasks.length === before) return res.status(404).json({ error: 'Task not found' });
  res.status(204).send();
});

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`TaskBoard running on port ${PORT}`));
}

module.exports = app;
