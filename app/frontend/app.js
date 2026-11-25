const API = "/api";

const form = document.getElementById("task-form");
const input = document.getElementById("task-input");
const taskList = document.getElementById("task-list");
const message = document.getElementById("message");

async function request(path, options = {}) {
    const response = await fetch(API + path, {
        headers: {
            "Content-Type": "application/json"
        },
        ...options
    });

    if (!response.ok) {
        throw new Error("Request failed: " + response.status);
    }

    return response.json();
}

function showError(error) {
    message.textContent = error.message;
}

async function checkHealth() {
    const status = document.getElementById("status");

    try {
        await request("/health");
        status.textContent = "System online";
        status.style.background = "#14532d";
    } catch {
        status.textContent = "System offline";
        status.style.background = "#991b1b";
    }
}

async function loadTasks() {
    try {
        const tasks = await request("/tasks");

        message.textContent = "";
        taskList.replaceChildren();

        const completed = tasks.filter(
            task => task.completed
        ).length;

        document.getElementById("total").textContent =
            tasks.length;

        document.getElementById("completed").textContent =
            completed;

        document.getElementById("pending").textContent =
            tasks.length - completed;

        for (const task of tasks) {
            const row = document.createElement("div");

            row.className = task.completed
                ? "task completed"
                : "task";

            const checkbox = document.createElement("input");

            checkbox.type = "checkbox";
            checkbox.checked = task.completed;

            checkbox.addEventListener("change", async () => {
                try {
                    await request(`/tasks/${task.id}`, {
                        method: "PATCH",
                        body: JSON.stringify({
                            completed: checkbox.checked
                        })
                    });

                    await loadTasks();
                } catch (error) {
                    checkbox.checked = task.completed;
                    showError(error);
                }
            });

            const title = document.createElement("span");
            title.textContent = task.title;

            const button = document.createElement("button");

            button.textContent = "Delete";
            button.className = "delete-btn";

            button.addEventListener("click", async () => {
                try {
                    await request(`/tasks/${task.id}`, {
                        method: "DELETE"
                    });

                    await loadTasks();
                } catch (error) {
                    showError(error);
                }
            });

            row.append(checkbox, title, button);
            taskList.appendChild(row);
        }
    } catch (error) {
        showError(error);
    }
}

form.addEventListener("submit", async (event) => {
    event.preventDefault();

    const title = input.value.trim();

    if (!title) return;

    try {
        await request("/tasks", {
            method: "POST",
            body: JSON.stringify({ title })
        });

        input.value = "";

        await loadTasks();
    } catch (error) {
        showError(error);
    }
});

checkHealth();
loadTasks();