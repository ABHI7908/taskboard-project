const request = require('supertest');
const app = require('../src/app');

describe('TaskBoard API', () => {
  test('GET /health returns 200 and status UP', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('UP');
  });

  test('GET /metrics returns Prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('process_cpu_user_seconds_total');
  });

  test('GET /tasks returns an array', async () => {
    const res = await request(app).get('/tasks');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('POST /tasks creates a new task', async () => {
    const res = await request(app).post('/tasks').send({ title: 'Write tests' });
    expect(res.statusCode).toBe(201);
    expect(res.body.title).toBe('Write tests');
    expect(res.body.done).toBe(false);
  });

  test('PUT /tasks/:id updates a task', async () => {
    const created = await request(app).post('/tasks').send({ title: 'Temp task' });
    const res = await request(app).put(`/tasks/${created.body.id}`).send({ done: true });
    expect(res.statusCode).toBe(200);
    expect(res.body.done).toBe(true);
  });

  test('DELETE /tasks/:id removes a task', async () => {
    const created = await request(app).post('/tasks').send({ title: 'Delete me' });
    const res = await request(app).delete(`/tasks/${created.body.id}`);
    expect(res.statusCode).toBe(204);
  });

  test('PUT /tasks/:id returns 404 for missing task', async () => {
    const res = await request(app).put('/tasks/999999').send({ done: true });
    expect(res.statusCode).toBe(404);
  });
});
